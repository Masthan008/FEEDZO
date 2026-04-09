import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_wallet_model.dart';

class CustomerWalletService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _wallets = _db.collection('customerWallets');
  static final CollectionReference _loyaltyPoints = _db.collection('customerLoyaltyPoints');

  static Stream<List<CustomerWalletModel>> watchAllWallets() {
    return _wallets.orderBy('balance', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => CustomerWalletModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<CustomerWalletModel?> watchWalletByCustomerId(String customerId) {
    return _wallets.where('customerId', isEqualTo: customerId).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return CustomerWalletModel.fromFirestore(snap.docs.first);
    });
  }

  static Future<CustomerWalletModel?> getWalletByCustomerId(String customerId) async {
    final snapshot = await _wallets.where('customerId', isEqualTo: customerId).get();
    if (snapshot.docs.isEmpty) return null;
    return CustomerWalletModel.fromFirestore(snapshot.docs.first);
  }

  static Future<void> addFunds(String customerId, double amount, String? reference) async {
    final wallet = await getWalletByCustomerId(customerId);
    final transaction = WalletTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'credit',
      amount: amount,
      description: 'Funds added by admin',
      reference: reference,
      createdAt: DateTime.now(),
    );

    if (wallet == null) {
      await _wallets.add({
        'customerId': customerId,
        'balance': amount,
        'transactions': [transaction.toMap()],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _wallets.doc(wallet.id).update({
        'balance': FieldValue.increment(amount),
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> deductFunds(String customerId, double amount, String description) async {
    final wallet = await getWalletByCustomerId(customerId);
    if (wallet == null) return;

    if (wallet.balance < amount) {
      throw Exception('Insufficient balance');
    }

    final transaction = WalletTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'debit',
      amount: amount,
      description: description,
      createdAt: DateTime.now(),
    );

    await _wallets.doc(wallet.id).update({
      'balance': FieldValue.increment(-amount),
      'transactions': FieldValue.arrayUnion([transaction.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addLoyaltyPoints(String customerId, int points, String description) async {
    final snapshot = await _loyaltyPoints.where('customerId', isEqualTo: customerId).get();
    final transaction = PointTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'earn',
      points: points,
      description: description,
      createdAt: DateTime.now(),
    );

    if (snapshot.docs.isEmpty) {
      await _loyaltyPoints.add({
        'customerId': customerId,
        'points': points,
        'transactions': [transaction.toMap()],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _loyaltyPoints.doc(snapshot.docs.first.id).update({
        'points': FieldValue.increment(points),
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> redeemLoyaltyPoints(String customerId, int points, String description) async {
    final snapshot = await _loyaltyPoints.where('customerId', isEqualTo: customerId).get();
    if (snapshot.docs.isEmpty) return;

    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    final currentPoints = data['points'] ?? 0;

    if (currentPoints < points) {
      throw Exception('Insufficient loyalty points');
    }

    final transaction = PointTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'redeem',
      points: points,
      description: description,
      createdAt: DateTime.now(),
    );

    await _loyaltyPoints.doc(snapshot.docs.first.id).update({
      'points': FieldValue.increment(-points),
      'transactions': FieldValue.arrayUnion([transaction.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
