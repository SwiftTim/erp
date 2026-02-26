// lib/data/models/finance_model.dart

import 'package:floor/floor.dart';

// ── Fee Structure ─────────────────────────────────────────────────────────────
@Entity(tableName: 'fee_structures')
class FeeStructureModel {
  @PrimaryKey()
  final String id;
  final String grade;
  final int term;
  @ColumnInfo(name: 'academic_year')
  final String academicYear;
  final double amount;
  final String? description;
  @ColumnInfo(name: 'created_by')
  final String createdBy;

  const FeeStructureModel({
    required this.id,
    required this.grade,
    required this.term,
    required this.academicYear,
    required this.amount,
    this.description,
    required this.createdBy,
  });
}

// ── Fee Transaction ───────────────────────────────────────────────────────────
@Entity(tableName: 'fee_transactions')
class FeeTransactionModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  @ColumnInfo(name: 'amount_paid')
  final double amountPaid;
  @ColumnInfo(name: 'payment_mode')
  final String paymentMode;   // M-Pesa | Bank Transfer | Cash | Cheque
  @ColumnInfo(name: 'reference_no')
  final String referenceNo;
  @ColumnInfo(name: 'balance_before')
  final double? balanceBefore;
  @ColumnInfo(name: 'balance_after')
  final double? balanceAfter;
  @ColumnInfo(name: 'recorded_by')
  final String recordedBy;
  @ColumnInfo(name: 'transaction_date')
  final int transactionDate;
  @ColumnInfo(name: 'receipt_url')
  final String? receiptUrl;
  final int synced;
  @ColumnInfo(name: 'is_voided')
  final int isVoided;
  @ColumnInfo(name: 'voided_by')
  final String? voidedBy;

  const FeeTransactionModel({
    required this.id,
    required this.studentId,
    required this.amountPaid,
    required this.paymentMode,
    required this.referenceNo,
    this.balanceBefore,
    this.balanceAfter,
    required this.recordedBy,
    required this.transactionDate,
    this.receiptUrl,
    this.synced = 0,
    this.isVoided = 0,
    this.voidedBy,
  });

  FeeTransactionModel copyWith({
    int? isVoided,
    String? voidedBy,
  }) => FeeTransactionModel(
    id: id,
    studentId: studentId,
    amountPaid: amountPaid,
    paymentMode: paymentMode,
    referenceNo: referenceNo,
    balanceBefore: balanceBefore,
    balanceAfter: balanceAfter,
    recordedBy: recordedBy,
    transactionDate: transactionDate,
    receiptUrl: receiptUrl,
    synced: synced,
    isVoided: isVoided ?? this.isVoided,
    voidedBy: voidedBy ?? this.voidedBy,
  );


  Map<String, dynamic> toFirestore() => {
        'id': id,
        'studentId': studentId,
        'amountPaid': amountPaid,
        'paymentMode': paymentMode,
        'referenceNo': referenceNo,
        'balanceBefore': balanceBefore,
        'balanceAfter': balanceAfter,
        'recordedBy': recordedBy,
        'transactionDate': transactionDate,
        'receiptUrl': receiptUrl,
      };
}

// ── Budget / Expenditure ───────────────────────────────────────────────────────
@Entity(tableName: 'expenditures')
class ExpenditureModel {
  @PrimaryKey()
  final String id;
  final String category;       // e.g. Salaries, Utilities, Supplies
  final double amount;
  final String description;
  @ColumnInfo(name: 'recorded_by')
  final String recordedBy;
  @ColumnInfo(name: 'expense_date')
  final int expenseDate;
  final int synced;
  @ColumnInfo(name: 'is_voided')
  final int isVoided;
  @ColumnInfo(name: 'voided_by')
  final String? voidedBy;

  const ExpenditureModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.recordedBy,
    required this.expenseDate,
    this.synced = 0,
    this.isVoided = 0,
    this.voidedBy,
  });

  ExpenditureModel copyWith({
    int? isVoided,
    String? voidedBy,
  }) => ExpenditureModel(
    id: id,
    category: category,
    amount: amount,
    description: description,
    recordedBy: recordedBy,
    expenseDate: expenseDate,
    synced: synced,
    isVoided: isVoided ?? this.isVoided,
    voidedBy: voidedBy ?? this.voidedBy,
  );


  Map<String, dynamic> toFirestore() => {
        'id': id,
        'category': category,
        'amount': amount,
        'description': description,
        'recordedBy': recordedBy,
        'expenseDate': expenseDate,
      };
}
