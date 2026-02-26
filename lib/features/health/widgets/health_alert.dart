// lib/features/health/widgets/health_alert.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/medical_model.dart';
import '../../auth/auth_provider.dart';
import 'dart:convert';

class HealthAlert extends ConsumerWidget {
  final String studentId;
  const HealthAlert({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<MedicalRecordModel?>(
      future: ref.read(databaseProvider.future).then((db) => db.medicalDao.findForStudent(studentId)),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.allergies == null) return const SizedBox.shrink();

        final List<dynamic> allergies = json.decode(snapshot.data!.allergies!);
        if (allergies.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRITICAL ALLERGY ALERT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'Student allergic to: ${allergies.join(", ")}',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
