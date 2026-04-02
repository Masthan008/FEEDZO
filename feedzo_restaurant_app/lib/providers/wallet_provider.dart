import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class WalletProvider extends ChangeNotifier {
  double _balance = 0.0;
  double _pendingPayout = 0.0;
  List<TransactionModel> _transactions = [];
  StreamSubscription? _subscription;
  StreamSubscription? _walletSubscription;
  bool _isLoading = false;
  String _bankName = '';
  String _accountNumber = '';
  bool _hasBankAccount = false;

  double get balance => _balance;
  double get pendingPayout => _pendingPayout;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get hasBankAccount => _hasBankAccount;
  String get bankName => _bankName;
  String get accountNumber => _accountNumber;

  void saveBankAccount(String bankName, String accountNumber) {
    _bankName = bankName;
    _accountNumber = accountNumber;
    _hasBankAccount = true;
    notifyListeners();
  }

  double get totalEarnings => _transactions
      .where((t) => t.type == TransactionType.earning)
      .fold(0, (s, t) => s + (t.amount));

  double get commissionDeducted => _transactions
      .where((t) => t.type == TransactionType.earning)
      .fold(0, (s, t) => s + (t.commission ?? 0));

  void init(String restaurantId) {
    _subscription?.cancel();
    _walletSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    // Listen to wallet balance in restaurant doc
    _walletSubscription = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .snapshots()
        .listen((snap) {
          if (snap.exists) {
            final data = snap.data() as Map<String, dynamic>;
            _balance = (data['walletBalance'] ?? 0.0).toDouble();
            _pendingPayout = (data['pendingPayout'] ?? 0.0).toDouble();
            notifyListeners();
          }
        });

    // Listen to transactions
    _subscription = FirebaseFirestore.instance
        .collection('transactions')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
          _transactions = snap.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
          _isLoading = false;
          notifyListeners();
        });
  }

  Future<void> requestWithdrawal(double amount, String restaurantId) async {
    if (amount <= _balance) {
      try {
        final batch = FirebaseFirestore.instance.batch();

        // 1. Create transaction
        final txnRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc();
        batch.set(txnRef, {
          'restaurantId': restaurantId,
          'description': 'Withdrawal Request',
          'amount': amount,
          'date': FieldValue.serverTimestamp(),
          'type': TransactionType.withdrawal.name,
          'status': 'pending',
        });

        // 2. Update balance
        final restRef = FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId);
        batch.update(restRef, {'walletBalance': FieldValue.increment(-amount)});

        await batch.commit();
      } catch (e) {
        debugPrint('Error requesting withdrawal: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _walletSubscription?.cancel();
    super.dispose();
  }
}
