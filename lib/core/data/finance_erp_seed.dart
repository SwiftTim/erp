import 'package:uuid/uuid.dart';
import '../../data/local/app_database.dart';
import '../../data/models/finance_erp_models.dart';
import '../../core/constants/app_constants.dart';
import 'dart:math';
import '../services/kenyan_tax_service.dart';

Future<void> seedFinanceErp(AppDatabase db) async {
  // Manual re-seed enabled - Clear existing data first for a professional state
  print('💵 Clearing old financial records...');
  await db.financeErpDao.clearStaff();
  await db.financeErpDao.clearFeeStructure();
  await db.financeErpDao.clearBillings();
  await db.financeErpDao.clearPayments();
  await db.financeErpDao.clearAmenities();
  await db.financeErpDao.clearStudentAmenities();
  await db.financeErpDao.clearPayroll();
  await db.financeErpDao.clearLoans();
  await db.financeErpDao.clearLoanRepayments();
  await db.financeErpDao.clearExpenses();
  await db.financeErpDao.clearAssets();
  await db.financeErpDao.clearRepairs();
  await db.financeErpDao.clearResourceRequests();
  await db.financeErpDao.clearRequestItems();
  await db.financeErpDao.clearBudgetApprovals();
  await db.financeErpDao.clearSalaryComponents();
  await db.financeErpDao.clearSalaryStructures();
  await db.financeErpDao.clearSalaryStructureAssignments();
  await db.financeErpDao.clearPayrollEntries();

  print('💵 Generating Deep Financial Data...');
  const uuid = Uuid();
  final random = Random();
  final now = DateTime.now().millisecondsSinceEpoch;
  final oneMonth = 2592000000;

  final users = await db.userDao.findAll();
  final students = await db.studentDao.findAll();
  
  print('Found ${users.length} users and ${students.length} students to seed.');

  // 1. SEED STAFF & MULTI-MONTH PAYROLL (Kenyan Compliant)
  final staffList = <String>[];
  for (final user in users) {
    if (user.roleLevel != AppConstants.roleParent && user.roleLevel != AppConstants.roleStudent) {
      staffList.add(user.id);
      
      final banks = ['Equity Bank', 'KCB Bank', 'Co-operative Bank', 'Absa Bank', 'NCBA'];
      final bank = banks[random.nextInt(banks.length)];
      
      await db.financeErpDao.insertStaff(FinanceStaff(
        staff_id: user.id,
        name: user.name,
        role: AppConstants.roleNames[user.roleLevel] ?? 'Staff',
        department: user.departmentId ?? 'Administration',
        employment_type: 'Full-Time',
        bank_name: bank,
        account_no: '01${random.nextInt(99999999).toString().padLeft(8, "0")}',
        bank_branch: 'Nairobi Main',
        date_hired: now - (oneMonth * 12),
      ));

      // Monthly Payroll for Jan, Feb, Mar 2026
      final basic = 45000.0 + (random.nextInt(40) * 1000);
      final months = ['January 2026', 'February 2026', 'March 2026'];
      for (int i = 0; i < months.length; i++) {
        final allowances = 5000.0 + random.nextInt(10000);
        final loanDeduction = (i == 2) ? 5000.0 : 0.0;
        
        final taxData = KenyanTaxService.calculatePayroll(basic, allowances);
        
        await db.financeErpDao.insertPayroll(Payroll(
          payroll_id: '${user.id}_${months[i].replaceAll(' ', '_')}',
          staff_id: user.id,
          month: months[i],
          basic_salary: basic,
          allowances: allowances,
          deductions: taxData['paye']! + taxData['nssf']! + taxData['shif']! + taxData['housing_levy']!,
          nssf: taxData['nssf']!,
          shif: taxData['shif']!,
          housing_levy: taxData['housing_levy']!,
          paye: taxData['paye']!,
          loan_deduction: loanDeduction,
          net_salary: (taxData['net']! - loanDeduction),
          status: i < 2 ? 'Paid' : 'Approved',
          processed_by: 'Accountant Jane',
          date_processed: now - (oneMonth * (2 - i)),
        ));
      }
    }
  }

  // 2. STAFF LOANS
  final uniqueStaff = staffList.toSet().toList();
  if (uniqueStaff.isNotEmpty) {
    for (int i = 0; i < min(3, uniqueStaff.length); i++) {
      final loanId = uuid.v4();
      final amt = 100000.0;
      final months = 10;
      final interest = amt * 0.05; // 5% flat
      final totalRepay = amt + interest;
      final monthly = totalRepay / months;

      await db.financeErpDao.insertLoan(StaffLoan(
        loan_id: loanId,
        staff_id: uniqueStaff[i],
        loan_amount: amt,
        interest_rate: 5.0,
        repayment_period: months,
        monthly_deduction: monthly,
        total_repayment: totalRepay,
        remaining_balance: totalRepay - (monthly * 2), // 2 months paid (Jan, Feb)
        status: 'Approved',
        approved_by: 'Headteacher Sarah',
        issue_date: now - (oneMonth * 3),
        created_at: now - (oneMonth * 3),
      ));
      
      // Repayments for Jan and Feb
      final seedMonths = ['January_2026', 'February_2026'];
      for (int m = 0; m < 2; m++) {
        await db.financeErpDao.insertLoanRepayment(LoanRepayment(
          repayment_id: uuid.v4(),
          loan_id: loanId,
          payroll_id: '${uniqueStaff[i]}_${seedMonths[m]}',
          amount: monthly,
          payment_date: now - (oneMonth * (2 - m)),
          deducted_from_payroll: true,
        ));
      }
    }
  }

  // 3. DETAILED FEE STRUCTURE BY GRADE
  final grades = ['PP1', 'PP2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9'];
  for (final grade in grades) {
    double tuition = grade.startsWith('Grade 7') || grade.startsWith('Grade 8') || grade.startsWith('Grade 9') ? 25000.0 : 18000.0;
    
    final feeId = 'Fee_${grade.replaceAll(' ', '_')}_Term1';
    await db.financeErpDao.insertFeeStructure(ErpFeeStructure(
      fee_id: feeId,
      fee_name: 'Tuition ($grade)',
      amount: tuition,
      term: 1,
      is_optional: false,
    ));
  }

  await db.financeErpDao.insertFeeStructure(ErpFeeStructure(fee_id: 'Fee_Activity_Term1', fee_name: 'Activity Fee', amount: 2000.0, term: 1, is_optional: false));
  await db.financeErpDao.insertFeeStructure(ErpFeeStructure(fee_id: 'Fee_ICT_Term1', fee_name: 'ICT & Lab', amount: 3500.0, term: 1, is_optional: false));

  // 4. AMENITIES
  final transportId = uuid.v4();
  final swimmingId = uuid.v4();
  await db.financeErpDao.insertAmenity(ErpAmenity(amenity_id: transportId, amenity_name: 'School Transport', fee_amount: 8500.0, billing_type: 'Per Term'));
  await db.financeErpDao.insertAmenity(ErpAmenity(amenity_id: swimmingId, amenity_name: 'Swimming Club', fee_amount: 3000.0, billing_type: 'Per Term'));

  // 5. STUDENT BILLING & VARIED PAYMENTS
  for (final student in students) {
    bool isJunior = student.grade.contains('7') || student.grade.contains('8') || student.grade.contains('9');
    double tuition = isJunior ? 25000.0 : 18000.0;
    double activity = 2000.0;
    double ict = 3500.0;
    double transport = random.nextBool() ? 8500.0 : 0.0;
    double swimming = random.nextBool() ? 3000.0 : 0.0;
    
    double total = tuition + activity + ict + transport + swimming;
    
    // Varied payment strategy
    double paidAmount = 0;
    String status = 'Defaulter';
    int r = random.nextInt(10);
    if (r > 7) {
       paidAmount = total; // Full paid
       status = 'Cleared';
    } else if (r > 3) {
       paidAmount = total * 0.6; // Partial
       status = 'Partial';
    } else {
       paidAmount = 5000.0; // Small payment
       status = 'Partial';
    }

    final billingId = 'Bill_${student.id}_Term1';
    await db.financeErpDao.insertBilling(StudentBilling(
      billing_id: billingId,
      student_id: student.id,
      term: 1,
      tuition: tuition,
      transport: transport,
      meals: 0.0,
      swimming: swimming,
      other_charges: activity + ict,
      total_amount: total,
      balance: total - paidAmount,
      status: status,
    ));

    if (paidAmount > 0) {
      await db.financeErpDao.insertPayment(ErpFeePayment(
        payment_id: uuid.v4(),
        student_id: student.id,
        amount_paid: paidAmount,
        payment_method: random.nextBool() ? 'M-Pesa' : 'Bank',
        transaction_code: 'ERP-${random.nextInt(999999)}',
        date_paid: now - (random.nextInt(30) * 86400000),
        received_by: 'Accountant Jane',
      ));
    }

    if (swimming > 0) {
      await db.financeErpDao.insertStudentAmenity(StudentAmenity(
        id: uuid.v4(),
        student_id: student.id,
        amenity_id: swimmingId,
        term: 1,
        status: 'Active',
      ));
    }
    if (transport > 0) {
      await db.financeErpDao.insertStudentAmenity(StudentAmenity(
        id: uuid.v4(),
        student_id: student.id,
        amenity_id: transportId,
        term: 1,
        status: 'Active',
      ));
    }
  }

  // 6. DETAILED EXPENSES
  final categories = ['Fuel', 'Food Supplies', 'Electricity', 'Water', 'Maintenance', 'Stationery', 'Internet'];
  for (final cat in categories) {
    await db.financeErpDao.insertExpense(ErpExpense(
      expense_id: uuid.v4(),
      category: cat,
      description: 'Monthly $cat payment',
      amount: 5000.0 + random.nextInt(20000),
      payment_method: 'Bank Transfer',
      date: now - random.nextInt(oneMonth.toInt()),
      approved_by: 'Headteacher Sarah',
    ));
  }

  // 7. ASSETS & REPAIRS
  final busId = uuid.v4();
  await db.financeErpDao.insertAsset(ErpAsset(
    asset_id: busId,
    asset_name: 'School Bus (62 Seater)',
    category: 'Transport',
    purchase_date: now - (oneMonth * 24),
    purchase_value: 5500000.0,
    condition: 'Good',
    status: 'Active',
  ));

  await db.financeErpDao.insertRepair(ErpRepair(
    repair_id: uuid.v4(),
    asset_id: busId,
    description: 'Brake Pad Replacement & Suspension Check',
    repair_cost: 18500.0,
    repair_date: now - (oneMonth ~/ 2),
    technician: 'Elite Auto Garage',
  ));

  // 8. RESOURCE PROCUREMENT REQUESTS
  if (uniqueStaff.length > 3) {
    // Request 1: Pending Budgeting
    final reqId1 = uuid.v4();
    await db.financeErpDao.insertResourceRequest(ResourceRequest(
      request_id: reqId1,
      teacher_id: uniqueStaff[0],
      purpose: 'Term 1 Classroom Stationery',
      status: 'Pending Budgeting',
      total_budget: 0,
      created_at: now - (oneMonth ~/ 4),
    ));
    await db.financeErpDao.insertRequestItem(ResourceRequestItem(request_id: reqId1, item_name: 'A4 Exercise Books', quantity: 200, price: 0, total: 0));
    await db.financeErpDao.insertRequestItem(ResourceRequestItem(request_id: reqId1, item_name: 'Fountain Pens', quantity: 50, price: 0, total: 0));

    // Request 2: Pending Approval
    final reqId2 = uuid.v4();
    await db.financeErpDao.insertResourceRequest(ResourceRequest(
      request_id: reqId2,
      teacher_id: uniqueStaff[1],
      purpose: 'Science Lab Chemicals Refill',
      status: 'Pending Approval',
      total_budget: 18400.0,
      created_at: now - (oneMonth ~/ 5),
    ));
    await db.financeErpDao.insertRequestItem(ResourceRequestItem(request_id: reqId2, item_name: 'Ammonium Nitrate', quantity: 5, price: 1500, total: 7500));
    await db.financeErpDao.insertRequestItem(ResourceRequestItem(request_id: reqId2, item_name: 'Distilled Water (20L)', quantity: 2, price: 5450, total: 10900));

    // Request 3: Approved
    final reqId3 = uuid.v4();
    await db.financeErpDao.insertResourceRequest(ResourceRequest(
      request_id: reqId3,
      teacher_id: uniqueStaff[2],
      purpose: 'Printing Ink & Toner',
      status: 'Approved',
      total_budget: 12500.0,
      created_at: now - (oneMonth ~/ 2),
    ));
    await db.financeErpDao.insertRequestItem(ResourceRequestItem(request_id: reqId3, item_name: 'Epson T664 Ink Set', quantity: 2, price: 4500, total: 9000));
    await db.financeErpDao.insertRequestItem(ResourceRequestItem(request_id: reqId3, item_name: 'Photocopy Paper (Reams)', quantity: 5, price: 700, total: 3500));
    
    // Auto-create expense for approved request
    await db.financeErpDao.insertExpense(ErpExpense(
      expense_id: 'EXP_RES_$reqId3',
      category: 'Stationery',
      description: 'Procurement: Printing Ink & Toner',
      amount: 12500.0,
      payment_method: 'Cash',
      date: now - (oneMonth ~/ 3),
      approved_by: 'Accountant Jane',
    ));
  }

  final labId = uuid.v4();
  await db.financeErpDao.insertAsset(ErpAsset(
    asset_id: labId,
    asset_name: 'Computer Lab (25 Desktop PCs)',
    category: 'ICT',
    purchase_date: now - (oneMonth * 6),
    purchase_value: 1250000.0,
    condition: 'Excellent',
    status: 'Active',
  ));

  print('✅ Deep Financial Seeding Completed.');

  // 9. ERPNEXT-STYLE SALARY COMPONENTS
  print('🏢 Seeding Salary Components & Structures...');
  final components = [
    const SalaryComponent(component_id: 'BASIC', name: 'Basic Salary', type: 'Earning', is_statutory: false, default_amount: 0),
    const SalaryComponent(component_id: 'HRA', name: 'House Allowance', type: 'Earning', is_statutory: false, default_amount: 5000),
    const SalaryComponent(component_id: 'TRANS', name: 'Transport Allowance', type: 'Earning', is_statutory: false, default_amount: 3000),
    const SalaryComponent(component_id: 'NSSF', name: 'NSSF (Tier I & II)', type: 'Deduction', is_statutory: true, default_amount: 2160),
    const SalaryComponent(component_id: 'SHIF', name: 'SHIF (2.75%)', type: 'Deduction', is_statutory: true, default_amount: 0),
    const SalaryComponent(component_id: 'HLEV', name: 'Housing Levy (1.5%)', type: 'Deduction', is_statutory: true, default_amount: 0),
    const SalaryComponent(component_id: 'PAYE', name: 'P.A.Y.E', type: 'Deduction', is_statutory: true, default_amount: 0),
  ];
  for (final c in components) await db.financeErpDao.insertSalaryComponent(c);

  final structures = [
    const SalaryStructure(structure_id: 'STR_TEACH', name: 'Teaching Staff Salary Structure', total_earnings: 15000, total_deductions: 5000),
    const SalaryStructure(structure_id: 'STR_ADMIN', name: 'Administrative Salary Structure', total_earnings: 20000, total_deductions: 7000),
  ];
  for (final s in structures) await db.financeErpDao.insertSalaryStructure(s);

  // Assign structures to staff
  for (int i = 0; i < uniqueStaff.length; i++) {
    final isTeacher = i % 2 == 0;
    await db.financeErpDao.insertStructureAssignment(SalaryStructureAssignment(
      assignment_id: uuid.v4(),
      staff_id: uniqueStaff[i],
      structure_id: isTeacher ? 'STR_TEACH' : 'STR_ADMIN',
      from_date: now - (oneMonth * 6),
      base_salary: isTeacher ? 48000.0 : 55000.0,
    ));
  }

  // Batch Payroll Entry for March 2026
  await db.financeErpDao.insertPayrollEntry(PayrollEntry(
    payroll_entry_id: 'PE_MARCH_2026_TEACH',
    month: 'March 2026',
    structure_id: 'STR_TEACH',
    status: 'Submitted',
    posting_date: now,
    count_processed: uniqueStaff.length ~/ 2,
  ));

  print('✅ ERPNext-style entities seeded.');
}
