// lib/data/local/daos/finance_dao.dart

import 'package:floor/floor.dart';
import '../../models/finance_model.dart';

@dao
abstract class FinanceDao {
  // ── Fee Structures ──────────────────────────────────────────────────────────
  @Query('SELECT * FROM fee_structures WHERE grade = :grade AND term = :term AND academic_year = :year LIMIT 1')
  Future<FeeStructureModel?> findFeeStructure(String grade, int term, String year);

  @Query('SELECT * FROM fee_structures WHERE academic_year = :year ORDER BY grade, term')
  Future<List<FeeStructureModel>> findAllForYear(String year);

  @insert
  Future<void> insertFeeStructure(FeeStructureModel fs);

  @update
  Future<void> updateFeeStructure(FeeStructureModel fs);

  // ── Transactions ────────────────────────────────────────────────────────────
  @Query('''
    SELECT * FROM fee_transactions
    WHERE student_id = :studentId AND is_voided = 0
    ORDER BY transaction_date DESC
  ''')
  Future<List<FeeTransactionModel>> findTransactionsForStudent(String studentId);

  @Query('SELECT SUM(amount_paid) FROM fee_transactions WHERE student_id = :studentId AND is_voided = 0')
  Future<double?> totalPaid(String studentId);

  @Query('SELECT * FROM fee_transactions WHERE id = :id')
  Future<FeeTransactionModel?> findTransactionById(String id);


  @Query('''
    SELECT * FROM fee_transactions
    WHERE transaction_date >= :fromDate AND transaction_date <= :toDate
    ORDER BY transaction_date DESC
  ''')
  Future<List<FeeTransactionModel>> findTransactionsInRange(int fromDate, int toDate);

  @Query('SELECT * FROM fee_transactions WHERE synced = 0')
  Future<List<FeeTransactionModel>> findUnsynced();

  @update
  Future<void> updateTransaction(FeeTransactionModel txn);


  @insert
  Future<void> insertTransaction(FeeTransactionModel txn);

  @Query('UPDATE fee_transactions SET synced = 1 WHERE id = :id')
  Future<void> markSynced(String id);

  // ── Expenditures ────────────────────────────────────────────────────────────
  @Query('SELECT * FROM expenditures WHERE is_voided = 0 ORDER BY expense_date DESC')
  Future<List<ExpenditureModel>> findAllExpenditures();

  @Query('SELECT SUM(amount) FROM expenditures WHERE expense_date >= :fromDate AND expense_date <= :toDate AND is_voided = 0')
  Future<double?> totalExpenditureInRange(int fromDate, int toDate);

  @Query('SELECT * FROM expenditures WHERE id = :id')
  Future<ExpenditureModel?> findExpenditureById(String id);

  @update
  Future<void> updateExpenditure(ExpenditureModel exp);


  @insert
  Future<void> insertExpenditure(ExpenditureModel expenditure);
}
