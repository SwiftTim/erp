// lib/core/services/payment_service.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_database.dart';
import '../../data/models/finance_model.dart';
import '../../features/auth/auth_provider.dart';
import 'audit_service.dart';

final paymentServiceProvider = Provider((ref) => PaymentService(ref));

class PaymentService {
  final Ref _ref;
  PaymentService(this._ref);

  Future<bool> initiateStkPush(String phoneNumber, double amount, String studentId) async {
    // ── Simulate MPesa STK Push ───────────────────────────────────────────────
    // In a real app, this would call the Safaricom Daraja API
    await Future.delayed(const Duration(seconds: 2));
    
    // We simulate 95% success rate for UX testing
    final bool success = (DateTime.now().millisecond % 100) < 95;
    
    if (success) {
      await recordPayment(
        studentId: studentId,
        amount: amount,
        reference: 'MPESA-${const Uuid().v4().substring(0, 8).toUpperCase()}',
        mode: 'M-Pesa STK',
      );
    }
    
    return success;
  }

  Future<void> recordPayment({
    required String studentId,
    required double amount,
    required String reference,
    required String mode,
  }) async {
    final db = await _ref.read(databaseProvider.future);
    final user = _ref.read(currentUserProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Get current balance (simplified: total fee - total paid)
    // In a real robust system, we would have a balance field or historical snapshot
    final totalPaidSoFar = await db.financeDao.totalPaid(studentId) ?? 0.0;
    
    final transaction = FeeTransactionModel(
      id: const Uuid().v4(),
      studentId: studentId,
      amountPaid: amount,
      paymentMode: mode,
      referenceNo: reference,
      balanceBefore: 0.0, // Should ideally be fetched
      balanceAfter: 0.0,  // Should ideally be calculated
      recordedBy: user?.id ?? 'SYSTEM',
      transactionDate: now,
    );

    await db.financeDao.insertTransaction(transaction);

    _ref.read(auditServiceProvider).log(
      'FEE_PAYMENT',
      'Finance',
      'Recorded $mode payment of KES $amount for Student ID: $studentId (Ref: $reference)'
    );
  }
}
