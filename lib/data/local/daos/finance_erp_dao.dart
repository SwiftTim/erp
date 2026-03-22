// lib/data/local/daos/finance_erp_dao.dart

import 'package:floor/floor.dart';
import '../../models/finance_erp_models.dart';

@dao
abstract class FinanceErpDao {
  // Staff
  @Query('SELECT * FROM staff')
  Future<List<FinanceStaff>> getAllStaff();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertStaff(FinanceStaff staff);
  @Query('DELETE FROM staff')
  Future<void> clearStaff();

  // Fee Structure
  @Query('SELECT * FROM fee_structure')
  Future<List<ErpFeeStructure>> getAllFeeStructures();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertFeeStructure(ErpFeeStructure fee);
  @Query('DELETE FROM fee_structure')
  Future<void> clearFeeStructure();

  // Student Billing
  @Query('SELECT * FROM student_billing')
  Future<List<StudentBilling>> getAllBillings();
  @Query('SELECT * FROM student_billing WHERE student_id = :studentId LIMIT 1')
  Future<StudentBilling?> getBillingByStudent(String studentId);
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBilling(StudentBilling billing);
  @Query('DELETE FROM student_billing')
  Future<void> clearBillings();

  // Payments
  @Query('SELECT * FROM fee_payments')
  Future<List<ErpFeePayment>> getAllPayments();
  @Query('SELECT * FROM fee_payments WHERE student_id = :studentId')
  Future<List<ErpFeePayment>> getPaymentsByStudent(String studentId);
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertPayment(ErpFeePayment payment);
  @Query('DELETE FROM fee_payments')
  Future<void> clearPayments();

  // Amenities
  @Query('SELECT * FROM amenities')
  Future<List<ErpAmenity>> getAllAmenities();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAmenity(ErpAmenity amenity);
  @Query('DELETE FROM amenities')
  Future<void> clearAmenities();

  // Student Amenities
  @Query('SELECT * FROM student_amenities')
  Future<List<StudentAmenity>> getAllStudentAmenities();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertStudentAmenity(StudentAmenity sa);
  @Query('DELETE FROM student_amenities')
  Future<void> clearStudentAmenities();

  // Payroll
  @Query('SELECT * FROM payroll')
  Future<List<Payroll>> getAllPayrolls();
  @Query('SELECT * FROM payroll WHERE staff_id = :staffId')
  Future<List<Payroll>> getPayrollByStaff(String staffId);
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertPayroll(Payroll payroll);
  @Query('DELETE FROM payroll')
  Future<void> clearPayroll();

  // Loans
  @Query('SELECT * FROM staff_loans')
  Future<List<StaffLoan>> getAllLoans();
  @Query('SELECT * FROM staff_loans WHERE staff_id = :staffId AND status = "Approved"')
  Future<List<StaffLoan>> getActiveLoansByStaff(String staffId);
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLoan(StaffLoan loan);
  @Query('DELETE FROM staff_loans')
  Future<void> clearLoans();

  // Loan Repayments
  @Query('SELECT * FROM loan_repayments')
  Future<List<LoanRepayment>> getAllLoanRepayments();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLoanRepayment(LoanRepayment lr);
  @Query('DELETE FROM loan_repayments')
  Future<void> clearLoanRepayments();

  // Expenses
  @Query('SELECT * FROM expenses')
  Future<List<ErpExpense>> getAllExpenses();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertExpense(ErpExpense expense);
  @Query('DELETE FROM expenses')
  Future<void> clearExpenses();

  // Assets
  @Query('SELECT * FROM assets')
  Future<List<ErpAsset>> getAllAssets();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAsset(ErpAsset asset);
  @Query('DELETE FROM assets')
  Future<void> clearAssets();

  // Repairs
  @Query('SELECT * FROM repairs')
  Future<List<ErpRepair>> getAllRepairs();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertRepair(ErpRepair repair);
  @Query('DELETE FROM repairs')
  Future<void> clearRepairs();

  // Resource Requests
  @Query('SELECT * FROM resource_requests')
  Future<List<ResourceRequest>> getAllResourceRequests();
  @Query('SELECT * FROM resource_requests WHERE teacher_id = :teacherId')
  Future<List<ResourceRequest>> getResourceRequestsByTeacher(String teacherId);
  @Query('SELECT * FROM resource_requests WHERE status = :status')
  Future<List<ResourceRequest>> getResourceRequestsByStatus(String status);
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertResourceRequest(ResourceRequest request);
  @Query('DELETE FROM resource_requests WHERE request_id = :requestId')
  Future<void> deleteResourceRequest(String requestId);

  @Query('DELETE FROM resource_requests')
  Future<void> clearResourceRequests();

  @Query('DELETE FROM resource_request_items')
  Future<void> clearRequestItems();

  // Request Items
  @Query('SELECT * FROM resource_request_items WHERE request_id = :requestId')
  Future<List<ResourceRequestItem>> getRequestItems(String requestId);
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertRequestItem(ResourceRequestItem item);
  @Query('DELETE FROM resource_request_items WHERE request_id = :requestId')
  Future<void> deleteRequestItems(String requestId);

  // Budget Approvals
  @Query('SELECT * FROM budget_approvals WHERE request_id = :requestId')
  Future<List<BudgetApproval>> getApprovalsByRequest(String requestId);
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBudgetApproval(BudgetApproval approval);

  @Query('DELETE FROM budget_approvals')
  Future<void> clearBudgetApprovals();

  @Query('DELETE FROM salary_components')
  Future<void> clearSalaryComponents();

  @Query('DELETE FROM salary_structures')
  Future<void> clearSalaryStructures();

  @Query('DELETE FROM salary_structure_assignments')
  Future<void> clearSalaryStructureAssignments();

  @Query('DELETE FROM payroll_entries')
  Future<void> clearPayrollEntries();

  // Advanced Payroll (ERPNext Style)
  @Query('SELECT * FROM salary_components')
  Future<List<SalaryComponent>> getAllSalaryComponents();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSalaryComponent(SalaryComponent component);

  @Query('SELECT * FROM salary_structures')
  Future<List<SalaryStructure>> getAllSalaryStructures();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSalaryStructure(SalaryStructure structure);

  @Query('SELECT * FROM salary_structure_assignments')
  Future<List<SalaryStructureAssignment>> getAllStructureAssignments();
  @Query('SELECT * FROM salary_structure_assignments WHERE staff_id = :staffId')
  Future<SalaryStructureAssignment?> getAssignmentByStaff(String staffId);
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertStructureAssignment(SalaryStructureAssignment assignment);

  @Query('SELECT * FROM payroll_entries')
  Future<List<PayrollEntry>> getAllPayrollEntries();
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertPayrollEntry(PayrollEntry entry);
}
