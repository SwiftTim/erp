// lib/data/models/finance_erp_models.dart
// ignore_for_file: non_constant_identifier_names

import 'package:floor/floor.dart';

@Entity(tableName: 'staff')
class FinanceStaff {
  @PrimaryKey()
  final String staff_id;
  final String name;
  final String role;
  final String department;
  final String employment_type;
  final String bank_name;     // Restored for Banking Integration
  final String account_no;   // Restored for Banking Integration
  final String bank_branch;   // Restored for Banking Integration
  final int date_hired;

  const FinanceStaff({
    required this.staff_id,
    required this.name,
    required this.role,
    required this.department,
    required this.employment_type,
    this.bank_name = 'Equity Bank',
    this.account_no = '0123456789012',
    this.bank_branch = 'Corporate',
    required this.date_hired,
  });
}

@Entity(tableName: 'fee_structure')
class ErpFeeStructure {
  @PrimaryKey()
  final String fee_id;
  final String fee_name;
  final double amount;
  final int term;
  final bool is_optional;

  const ErpFeeStructure({
    required this.fee_id,
    required this.fee_name,
    required this.amount,
    required this.term,
    required this.is_optional,
  });
}

@Entity(tableName: 'student_billing')
class StudentBilling {
  @PrimaryKey()
  final String billing_id;
  final String student_id;
  final int term;
  final double tuition;
  final double transport;
  final double meals;
  final double swimming;
  final double other_charges;
  final double total_amount;
  final double balance;
  final String status;

  const StudentBilling({
    required this.billing_id,
    required this.student_id,
    required this.term,
    required this.tuition,
    required this.transport,
    required this.meals,
    required this.swimming,
    required this.other_charges,
    required this.total_amount,
    required this.balance,
    required this.status,
  });
}

@Entity(tableName: 'fee_payments')
class ErpFeePayment {
  @PrimaryKey()
  final String payment_id;
  final String student_id;
  final double amount_paid;
  final String payment_method;
  final String transaction_code;
  final int date_paid;
  final String received_by;

  const ErpFeePayment({
    required this.payment_id,
    required this.student_id,
    required this.amount_paid,
    required this.payment_method,
    required this.transaction_code,
    required this.date_paid,
    required this.received_by,
  });
}

@Entity(tableName: 'amenities')
class ErpAmenity {
  @PrimaryKey()
  final String amenity_id;
  final String amenity_name;
  final double fee_amount;
  final String billing_type;

  const ErpAmenity({
    required this.amenity_id,
    required this.amenity_name,
    required this.fee_amount,
    required this.billing_type,
  });
}

@Entity(tableName: 'student_amenities')
class StudentAmenity {
  @PrimaryKey()
  final String id;
  final String student_id;
  final String amenity_id;
  final int term;
  final String status;

  const StudentAmenity({
    required this.id,
    required this.student_id,
    required this.amenity_id,
    required this.term,
    required this.status,
  });
}

@Entity(tableName: 'payroll')
class Payroll {
  @PrimaryKey()
  final String payroll_id;
  final String staff_id;
  final String month;
  final double basic_salary;
  final double allowances;
  final double deductions; // Restored for DB schema consistency
  final double nssf;
  final double shif;
  final double housing_levy;
  final double paye;
  final double loan_deduction;
  final double net_salary;
  final String status;       // Draft, Approved, Paid
  final String processed_by;
  final int date_processed;

  const Payroll({
    required this.payroll_id,
    required this.staff_id,
    required this.month,
    required this.basic_salary,
    required this.allowances,
    required this.deductions,
    required this.nssf,
    required this.shif,
    required this.housing_levy,
    required this.paye,
    required this.loan_deduction,
    required this.net_salary,
    this.status = 'Draft',
    required this.processed_by,
    required this.date_processed,
  });
}

@Entity(tableName: 'staff_loans')
class StaffLoan {
  @PrimaryKey()
  final String loan_id;
  final String staff_id;
  final double loan_amount;
  final double interest_rate;
  final int repayment_period;    // months
  final double monthly_deduction;
  final double total_repayment;
  final double remaining_balance;
  final String status;           // Pending, Approved, Rejected, Completed
  final String? approved_by;
  final int issue_date;
  final int created_at;

  const StaffLoan({
    required this.loan_id,
    required this.staff_id,
    required this.loan_amount,
    required this.interest_rate,
    required this.repayment_period,
    required this.monthly_deduction,
    required this.total_repayment,
    required this.remaining_balance,
    required this.status,
    this.approved_by,
    required this.issue_date,
    required this.created_at,
  });
}

@Entity(tableName: 'loan_repayments')
class LoanRepayment {
  @PrimaryKey()
  final String repayment_id;
  final String loan_id;
  final String? payroll_id; // Link to payroll if deducted automatically
  final double amount;
  final int payment_date;
  final bool deducted_from_payroll;

  const LoanRepayment({
    required this.repayment_id,
    required this.loan_id,
    this.payroll_id,
    required this.amount,
    required this.payment_date,
    required this.deducted_from_payroll,
  });
}

@Entity(tableName: 'expenses')
class ErpExpense {
  @PrimaryKey()
  final String expense_id;
  final String category;
  final String description;
  final double amount;
  final String payment_method;
  final int date;
  final String approved_by;

  const ErpExpense({
    required this.expense_id,
    required this.category,
    required this.description,
    required this.amount,
    required this.payment_method,
    required this.date,
    required this.approved_by,
  });
}

@Entity(tableName: 'assets')
class ErpAsset {
  @PrimaryKey()
  final String asset_id;
  final String asset_name;
  final String category;
  final int purchase_date;
  final double purchase_value;
  final String condition;
  final String status;

  const ErpAsset({
    required this.asset_id,
    required this.asset_name,
    required this.category,
    required this.purchase_date,
    required this.purchase_value,
    required this.condition,
    required this.status,
  });
}

@Entity(tableName: 'repairs')
class ErpRepair {
  @PrimaryKey()
  final String repair_id;
  final String asset_id;
  final String description;
  final double repair_cost;
  final int repair_date;
  final String technician;

  const ErpRepair({
    required this.repair_id,
    required this.asset_id,
    required this.description,
    required this.repair_cost,
    required this.repair_date,
    required this.technician,
  });
}

@Entity(tableName: 'resource_requests')
class ResourceRequest {
  @PrimaryKey()
  final String request_id;
  final String teacher_id;
  final String purpose;
  final String status; // Pending Budgeting, Pending Approval, Approved, Rejected
  final double total_budget;
  final int created_at;

  const ResourceRequest({
    required this.request_id,
    required this.teacher_id,
    required this.purpose,
    required this.status,
    required this.total_budget,
    required this.created_at,
  });
}

@Entity(tableName: 'resource_request_items')
class ResourceRequestItem {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String request_id;
  final String item_name;
  final int quantity;
  final double price;
  final double total;

  const ResourceRequestItem({
    this.id,
    required this.request_id,
    required this.item_name,
    required this.quantity,
    required this.price,
    required this.total,
  });
}

@Entity(tableName: 'budget_approvals')
class BudgetApproval {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String request_id;
  final String approved_by;
  final String decision; // Approved, Rejected, Changes Requested
  final String comments;
  final int date;

  const BudgetApproval({
    this.id,
    required this.request_id,
    required this.approved_by,
    required this.decision,
    required this.comments,
    required this.date,
  });
}

// ── ERPNext-Style Advanced Payroll Entities ────────────────────────────────

@Entity(tableName: 'salary_components')
class SalaryComponent {
  @PrimaryKey()
  final String component_id;
  final String name;
  final String type; // Earning, Deduction
  final String? description;
  final bool is_statutory; // If true, tied to government laws
  final bool is_tax_applicable;
  final bool is_attendance_linked;
  final double default_amount;

  const SalaryComponent({
    required this.component_id,
    required this.name,
    required this.type,
    this.description,
    this.is_statutory = false,
    this.is_tax_applicable = false,
    this.is_attendance_linked = false,
    this.default_amount = 0.0,
  });
}

@Entity(tableName: 'salary_structures')
class SalaryStructure {
  @PrimaryKey()
  final String structure_id;
  final String name;
  final String company; 
  final bool is_active;
  final double total_earnings;
  final double total_deductions;

  const SalaryStructure({
    required this.structure_id,
    required this.name,
    this.company = 'Default School',
    this.is_active = true,
    this.total_earnings = 0.0,
    this.total_deductions = 0.0,
  });
}

@Entity(tableName: 'salary_structure_assignments')
class SalaryStructureAssignment {
  @PrimaryKey()
  final String assignment_id;
  final String staff_id;
  final String structure_id;
  final int from_date;
  final double base_salary;

  const SalaryStructureAssignment({
    required this.assignment_id,
    required this.staff_id,
    required this.structure_id,
    required this.from_date,
    required this.base_salary,
  });
}

@Entity(tableName: 'payroll_entries')
class PayrollEntry {
  @PrimaryKey()
  final String payroll_entry_id;
  final String month;
  final String structure_id; // Process by structure (Admin, Teachers, etc)
  final String status; // Draft, Submitted, Cancelled
  final int posting_date;
  final int count_processed;

  const PayrollEntry({
    required this.payroll_entry_id,
    required this.month,
    required this.structure_id,
    required this.status,
    required this.posting_date,
    this.count_processed = 0,
  });
}
