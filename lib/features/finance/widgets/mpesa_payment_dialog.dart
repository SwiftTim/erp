// lib/features/finance/widgets/mpesa_payment_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/finance_model.dart';
import '../../auth/auth_provider.dart';

class MpesaPaymentDialog extends ConsumerStatefulWidget {
  final StudentModel student;
  const MpesaPaymentDialog({super.key, required this.student});

  @override
  ConsumerState<MpesaPaymentDialog> createState() => _MpesaPaymentDialogState();
}

class _MpesaPaymentDialogState extends ConsumerState<MpesaPaymentDialog> {
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _processing = false;
  String? _status;

  Future<void> _initiatePayment() async {
    if (_amountController.text.isEmpty || _phoneController.text.isEmpty) return;
    
    setState(() {
      _processing = true;
      _status = 'Sending STK Push to Safaricom...';
    });

    // Simulate STK Push delay
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() {
      _status = 'Waiting for Learner Parent to enter PIN...';
    });

    await Future.delayed(const Duration(seconds: 4));

    // Record the transaction locally (Offline-first sync later)
    final user = ref.read(currentUserProvider);
    final db = await ref.read(databaseProvider.future);
    
    final amount = double.parse(_amountController.text);
    final txn = FeeTransactionModel(
      id: const Uuid().v4(),
      studentId: widget.student.id,
      amountPaid: amount,
      paymentMode: 'M-Pesa (STK)',
      referenceNo: 'MPESA-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      transactionDate: DateTime.now().millisecondsSinceEpoch,
      recordedBy: user?.id ?? 'parent-self',
      synced: 0,
    );

    await db.financeDao.insertTransaction(txn);

    if (mounted) {
      setState(() {
        _processing = false;
        _status = 'Success! Receipt generated.';
      });
      
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/M-PESA_LOGO-01.svg/512px-M-PESA_LOGO-01.svg.png', height: 24, 
            errorBuilder: (_, __, ___) => const Icon(Icons.payment, color: Colors.green)),
          const SizedBox(width: 12),
          const Text('Lipa na M-Pesa'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_processing && _status == null) ...[
            Text('Paying school fees for ${widget.student.fullName}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                prefixText: 'KES ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                hintText: '07xx xxx xxx',
                border: OutlineInputBorder(),
              ),
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]
        ],
      ),
      actions: [
        if (!_processing) ...[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _initiatePayment, 
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF006B3C)),
            child: const Text('Pay Now'),
          ),
        ]
      ],
    );
  }
}
