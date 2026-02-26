// lib/features/assessment/widgets/rubric_button.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Large tappable button for EE / ME / AE / BE selection.
/// Optimised for thumb tap on mobile.
class RubricButton extends StatelessWidget {
  final int score;         // 1–4
  final bool isSelected;
  final VoidCallback onTap;

  const RubricButton({
    super.key,
    required this.score,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.rubricColor(score);
    final code = AppConstants.rubricCode[score] ?? '?';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _shortLabel(score),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortLabel(int score) {
    switch (score) {
      case 4: return 'Exceeding';
      case 3: return 'Meeting';
      case 2: return 'Approaching';
      case 1: return 'Below';
      default: return '';
    }
  }
}
