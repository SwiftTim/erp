// lib/core/services/kenyan_tax_service.dart

class KenyanTaxService {
  // PAYE Bands 2024/2025 (Monthly)
  static const double personalRelief = 2400.0;
  
  static double calculateNSSF(double basicSalary) {
    // Phase II Implementation (2024/2025)
    // Tier I: Up to 7,000 (6% = 420 max)
    // Tier II: 7,001 to 36,000 (6% = 1,740 max)
    // Total Max = 2,160
    
    double tier1 = basicSalary > 7000 ? 7000 : basicSalary;
    double tier1Contribution = tier1 * 0.06;
    
    double tier2Contribution = 0;
    if (basicSalary > 7000) {
      double tier2Amount = basicSalary > 36000 ? 36000 - 7000 : basicSalary - 7000;
      tier2Contribution = tier2Amount * 0.06;
    }
    
    return tier1Contribution + tier2Contribution;
  }

  static double calculateSHIF(double grossSalary) {
    // 2.75% of Gross Salary (formerly NHIF)
    return grossSalary * 0.0275;
  }

  static double calculateHousingLevy(double grossSalary) {
    // 1.5% of Gross Salary
    return grossSalary * 0.015;
  }

  static double calculatePAYE(double grossSalary, double nssf, double shif, double housingLevy) {
    // Taxable Income = Gross - NSSF - SHIF - Housing Levy
    // (As of Dec 2024, SHIF and Housing Levy are tax-deductible)
    double taxableIncome = grossSalary - nssf - shif - housingLevy;
    
    if (taxableIncome <= 24000) return 0; // Below taxable threshold after relief

    double tax = 0;
    double remaining = taxableIncome;

    // 10% on first 24,000
    double band1 = remaining > 24000 ? 24000 : remaining;
    tax += band1 * 0.10;
    remaining -= band1;

    // 25% on next 8,333
    if (remaining > 0) {
      double band2 = remaining > 8333 ? 8333 : remaining;
      tax += band2 * 0.25;
      remaining -= band2;
    }

    // 30% on next 467,667
    if (remaining > 0) {
      double band3 = remaining > 467667 ? 467667 : remaining;
      tax += band3 * 0.30;
      remaining -= band3;
    }

    // 32.5% on next 300,000
    if (remaining > 0) {
      double band4 = remaining > 300000 ? 300000 : remaining;
      tax += band4 * 0.325;
      remaining -= band4;
    }

    // 35% on anything above 800,000
    if (remaining > 0) {
      tax += remaining * 0.35;
    }

    // Subtract Personal Relief
    double finalTax = tax - personalRelief;
    return finalTax > 0 ? finalTax : 0;
  }

  static Map<String, double> calculatePayroll(double basicSalary, double allowances) {
    double gross = basicSalary + allowances;
    double nssf = calculateNSSF(basicSalary);
    double shif = calculateSHIF(gross);
    double housingLevy = calculateHousingLevy(gross);
    double paye = calculatePAYE(gross, nssf, shif, housingLevy);
    
    double totalDeductions = nssf + shif + housingLevy + paye;
    double net = gross - totalDeductions;

    return {
      'gross': gross,
      'nssf': nssf,
      'shif': shif,
      'housing_levy': housingLevy,
      'paye': paye,
      'total_deductions': totalDeductions,
      'net': net,
    };
  }
}
