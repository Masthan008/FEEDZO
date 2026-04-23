import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';

class WalletService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _wallets = _db.collection('customerWallets');

  static Stream<WalletModel?> watchWallet(String userId) {
    return _wallets.where('userId', isEqualTo: userId).limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return WalletModel.fromFirestore(snap.docs.first);
    });
  }

  static Future<WalletModel?> getWallet(String userId) async {
    final snapshot = await _wallets.where('userId', isEqualTo: userId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return WalletModel.fromFirestore(snapshot.docs.first);
  }

  static Future<String> addFunds(String userId, double amount, String description, {String? orderId, String? referenceId}) async {
    final wallet = await getWallet(userId);
    if (wallet == null) {
      final newWallet = WalletModel(
        id: '',
        userId: userId,
        balance: amount,
        bonus: 0,
        transactions: [
          WalletTransaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'credit',
            amount: amount,
            description: description,
            createdAt: DateTime.now(),
            orderId: orderId,
            referenceId: referenceId,
          ),
        ],
        updatedAt: DateTime.now(),
      );
      final docRef = await _wallets.add(newWallet.toMap());
      return docRef.id;
    } else {
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'credit',
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
        orderId: orderId,
        referenceId: referenceId,
      );
      await _wallets.doc(wallet.id).update({
        'balance': wallet.balance + amount,
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return wallet.id;
    }
  }

  static Future<String> deductFunds(String userId, double amount, String description, {String? orderId}) async {
    final wallet = await getWallet(userId);
    if (wallet == null) {
      throw Exception('Wallet not found');
    }
    if (wallet.balance < amount) {
      throw Exception('Insufficient balance');
    }
    final transaction = WalletTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'debit',
      amount: amount,
      description: description,
      createdAt: DateTime.now(),
      orderId: orderId,
    );
    await _wallets.doc(wallet.id).update({
      'balance': wallet.balance - amount,
      'transactions': FieldValue.arrayUnion([transaction.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return wallet.id;
  }

  static Future<String> addBonus(String userId, double amount, String description) async {
    final wallet = await getWallet(userId);
    if (wallet == null) {
      final newWallet = WalletModel(
        id: '',
        userId: userId,
        balance: 0,
        bonus: amount,
        transactions: [
          WalletTransaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'bonus_credit',
            amount: amount,
            description: description,
            createdAt: DateTime.now(),
          ),
        ],
        updatedAt: DateTime.now(),
      );
      final docRef = await _wallets.add(newWallet.toMap());
      return docRef.id;
    } else {
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'bonus_credit',
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
      );
      await _wallets.doc(wallet.id).update({
        'bonus': wallet.bonus + amount,
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return wallet.id;
    }
  }
}
