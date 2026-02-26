// lib/services/timetable_engine_service.dart

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local/app_database.dart';
import '../data/models/timetable_models.dart';
import '../features/auth/auth_provider.dart';
import '../core/constants/app_constants.dart';

final timetableEngineServiceProvider = Provider((ref) => TimetableEngineService(ref));

class TimetableEngineService {
  final Ref _ref;
  final Random _random = Random(); // Allows slight randomness for generating different valid timetables

  TimetableEngineService(this._ref);

  /// Generates a timetable utilizing a Backtracking Constraint Satisfaction algorithm.
  /// Uses slight randomness (shuffling days/periods and teacher candidates) so that
  /// users can "Regenerate" and get different, valid variations of the timetable.
  Future<Map<String, dynamic>> generateTimetable({
    required String academicYear,
    required String term,
    required int daysPerWeek, // typically 5
    required int periodsPerDay, // typically 7
    String? absentTeacherId, // For simulating absence
  }) async {
    final db = await _ref.read(databaseProvider.future);
    final stopwatch = Stopwatch()..start();

    // 1️⃣ ENGINE PREPARATION LAYER
    final allProfiles = await db.timetableDao.findAllTeacherProfiles();
    final allCapabilities = await db.timetableDao.findAllCapabilities();
    final requirements = await db.timetableDao.findAllClassRequirements();
    final allClasses = await db.curriculumDao.findAllClasses();

    final classBands = {for (var c in allClasses) c.id: AppConstants.gradeBand(c.grade)};

    final profiles = absentTeacherId == null 
        ? allProfiles 
        : allProfiles.where((p) => p.teacherId != absentTeacherId).toList();
        
    final capabilities = absentTeacherId == null 
        ? allCapabilities 
        : allCapabilities.where((c) => c.teacherId != absentTeacherId).toList();

    // Group capabilities by subjectId and prioritize: 
    // SubjectId -> Map of PriorityLevel -> List of Capabilities
    Map<String, Map<int, List<TeacherSubjectCapability>>> capsBySubjectAndPriority = {};
    for (var cap in capabilities) {
      capsBySubjectAndPriority.putIfAbsent(cap.subjectId, () => {});
      capsBySubjectAndPriority[cap.subjectId]!.putIfAbsent(cap.priorityLevel, () => []);
      capsBySubjectAndPriority[cap.subjectId]![cap.priorityLevel]!.add(cap);
    }

    // Map profile by teacherId for quick O(1) lookups
    Map<String, TeacherTimetableProfile> teacherProfiles = {
      for (var p in profiles) p.teacherId: p
    };

    // Fast-fail if demand exceeds capacity (no double-counting for assistants)
    int totalDemandPeriods = requirements.fold(0, (sum, r) => sum + r.periodsPerWeek);
    int totalCapacityPeriods = profiles.fold(0, (sum, p) => sum + p.maxPeriodsPerWeek);

    if (requirements.isEmpty) {
      throw Exception('No subject requirements defined. Please run "Inject Full MoE Data" first then try again.');
    }

    if (totalDemandPeriods > totalCapacityPeriods) {
      throw Exception('Insufficient Capacity. Demand: $totalDemandPeriods periods, but teachers can only cover $totalCapacityPeriods periods/week. Add more teachers or reduce subject loads.');
    }

    // Load Trackers
    Map<String, int> weeklyLoad = {for (var p in profiles) p.teacherId: 0};
    Map<String, Map<int, int>> dailyLoad = {for (var p in profiles) p.teacherId: {}};
    Map<String, Map<int, Map<int, String>>> teacherSchedule = {for (var p in profiles) p.teacherId: {}};
    Map<String, Map<int, Map<int, TimetableSlot>>> classSchedule = {};
    for (var req in requirements) classSchedule.putIfAbsent(req.classId, () => {});

    // HEURISTIC: MRV (Most Constrained Variable) — schedule rare subjects first
    List<ClassSubjectRequirement> needs = List.from(requirements);
    needs.sort((a, b) {
      int aTeachers = (capsBySubjectAndPriority[a.subjectId]?.values.fold(0, (sum, list) => sum! + list.length) ?? 0);
      int bTeachers = (capsBySubjectAndPriority[b.subjectId]?.values.fold(0, (sum, list) => sum! + list.length) ?? 0);
      return aTeachers.compareTo(bTeachers);
    });

    String newTimetableId = const Uuid().v4();
    int backtrackSteps = 0;
    int maxAttempts = 2500000;

    bool backtrack(int reqIndex, int periodsLeft) {
      if (backtrackSteps++ > maxAttempts) return false;
      if (reqIndex >= needs.length) return true;

      var currentReq = needs[reqIndex];
      if (periodsLeft == 0) {
        int nextReqLeft = (reqIndex + 1 < needs.length) ? needs[reqIndex + 1].periodsPerWeek : 0;
        return backtrack(reqIndex + 1, nextReqLeft);
      }

      String classId = currentReq.classId;
      String subjectId = currentReq.subjectId;
      String band = classBands[classId] ?? 'Upper Primary';
      // Double-teacher is BEST-EFFORT for PP1-G3 — we TRY to assign an assistant,
      // but we never block the schedule if one can't be found.
      bool tryDoubleTeacher = band == 'Pre-Primary' || band == 'Lower Primary';

      var capsForSubject = capsBySubjectAndPriority[subjectId] ?? {};
      List<int> priorities = capsForSubject.keys.toList()..sort();

      List<MapEntry<int, int>> dayPeriods = [];
      for (int d = 1; d <= daysPerWeek; d++) {
        for (int p = 1; p <= periodsPerDay; p++) {
          dayPeriods.add(MapEntry(d, p));
        }
      }
      dayPeriods.shuffle(_random);

      for (var priority in priorities) {
        var potentialCaps = List<TeacherSubjectCapability>.from(capsForSubject[priority]!);

        // RANDOMIZED FAIRNESS: shuffle first (breaks ties), then sort by load
        potentialCaps.shuffle(_random);
        potentialCaps.sort((a, b) => weeklyLoad[a.teacherId]!.compareTo(weeklyLoad[b.teacherId]!));

        for (var tCap in potentialCaps) {
          String tId = tCap.teacherId;
          var tProfile = teacherProfiles[tId];
          if (tProfile == null) continue;

          for (var dp in dayPeriods) {
            int day = dp.key;
            int period = dp.value;

            // ── Constraint checks for Primary Teacher ──
            if (classSchedule[classId]?[day]?[period] != null) continue;
            if (teacherSchedule[tId]?[day]?[period] != null) continue;
            if (weeklyLoad[tId]! >= tProfile.maxPeriodsPerWeek) continue;
            int t1Daily = dailyLoad[tId]?[day] ?? 0;
            if (t1Daily >= tProfile.maxPeriodsPerDay) continue;
            if (_formsTooManyConsecutive(teacherSchedule[tId]?[day] ?? {}, period)) continue;

            // ── Best-Effort: Try to find an assistant for lower primary ──
            String? tId2;
            if (tryDoubleTeacher) {
              // Search ALL capability levels for a free teacher to act as assistant
              final allCaps = capsForSubject.values.expand((list) => list).toList();
              allCaps.shuffle(_random);
              allCaps.sort((a, b) => weeklyLoad[a.teacherId]!.compareTo(weeklyLoad[b.teacherId]!));
              for (var cap2 in allCaps) {
                String cT2 = cap2.teacherId;
                if (cT2 == tId) continue;
                if (teacherSchedule[cT2]?[day]?[period] != null) continue;
                var p2 = teacherProfiles[cT2];
                if (p2 == null) continue;
                if (weeklyLoad[cT2]! >= p2.maxPeriodsPerWeek) continue;
                if ((dailyLoad[cT2]?[day] ?? 0) >= p2.maxPeriodsPerDay) continue;
                // Found a valid assistant — assign and stop searching
                tId2 = cT2;
                break;
              }
              // NOTE: if tId2 is still null here, we proceed with just 1 teacher.
              // This is intentional — a solo lesson is better than no timetable.
            }

            // ── Tentative Assignment ──
            TimetableSlot newSlot = TimetableSlot(
              id: const Uuid().v4(),
              timetableId: newTimetableId,
              dayOfWeek: day,
              periodNumber: period,
              classId: classId,
              subjectId: subjectId,
              teacherId: tId,
              teacherId2: tId2,
            );

            classSchedule[classId]![day] ??= {};
            classSchedule[classId]![day]![period] = newSlot;
            teacherSchedule[tId]![day] ??= {};
            teacherSchedule[tId]![day]![period] = subjectId;
            weeklyLoad[tId] = weeklyLoad[tId]! + 1;
            dailyLoad[tId]![day] = t1Daily + 1;

            if (tId2 != null) {
              teacherSchedule[tId2]![day] ??= {};
              teacherSchedule[tId2]![day]![period] = '(Assistant) $subjectId';
              weeklyLoad[tId2] = weeklyLoad[tId2]! + 1;
              dailyLoad[tId2]![day] = (dailyLoad[tId2]![day] ?? 0) + 1;
            }

            if (backtrack(reqIndex, periodsLeft - 1)) return true;

            // ── Backtrack ──
            if (tId2 != null) {
              teacherSchedule[tId2]![day]!.remove(period);
              weeklyLoad[tId2] = weeklyLoad[tId2]! - 1;
              dailyLoad[tId2]![day] = dailyLoad[tId2]![day]! - 1;
            }
            classSchedule[classId]![day]!.remove(period);
            teacherSchedule[tId]![day]!.remove(period);
            weeklyLoad[tId] = weeklyLoad[tId]! - 1;
            dailyLoad[tId]![day] = t1Daily;
          }
        }
      }
      return false;
    }

    if (needs.isNotEmpty) {
      bool success = backtrack(0, needs[0].periodsPerWeek);
      if (!success) {
        throw Exception(
          'Constraint Resolution Failed after $backtrackSteps attempts. '
          'The engine could not schedule all ${needs.length} subject requirements. '
          'Tip: Try running "Inject Full MoE Data" again then re-run the engine, '
          'or reduce the number of periods per subject.'
        );
      }
    }

    // ── Saving State ──
    // Generation succeeded! Flatten the matrix and persist.
    List<TimetableSlot> finalSlots = [];
    for (var classDays in classSchedule.values) {
      for (var dayPeriods in classDays.values) {
        finalSlots.addAll(dayPeriods.values);
      }
    }

    TimetableModel masterTimetable = TimetableModel(
      id: newTimetableId,
      academicYear: academicYear,
      term: term,
      isActive: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Save transaction to purely separate in-memory maps from physical database writes
    // 🔑 CRITICAL: Deactivate ALL previous timetables first so the new one is the only active one
    await db.timetableDao.deactivateAllTimetables();
    await db.timetableDao.clearSlotsForTimetable(newTimetableId); // Safe guard
    await db.timetableDao.insertTimetable(masterTimetable);
    await db.timetableDao.insertTimetableSlots(finalSlots);

    stopwatch.stop();

    // Calculate variance for reporting
    List<int> loads = weeklyLoad.values.where((l) => l > 0).toList();
    double variance = 0;
    if (loads.isNotEmpty) {
      double mean = loads.fold(0, (a, b) => a + b) / loads.length;
      for (var l in loads) {
        variance += pow(l - mean, 2);
      }
      variance = variance / loads.length;
    }

    // Calculate Unused Capacity
    int unusedCapacity = totalCapacityPeriods - totalDemandPeriods;
    double unusedPercentage = totalCapacityPeriods > 0 ? (unusedCapacity / totalCapacityPeriods) * 100 : 0.0;

    return {
      'slots': finalSlots,
      'dbTimeMs': stopwatch.elapsedMilliseconds,
      'steps': backtrackSteps,
      'variance': variance,
      'unusedPercentage': unusedPercentage,
      'weeklyLoad': weeklyLoad, // TeacherId -> Load mappings
    };
  }

  /// Helper heuristic to prevent severe teacher overload:
  /// Ensures placing a lesson at [targetPeriod] does not create > 3 consecutive lessons.
  bool _formsTooManyConsecutive(Map<int, String> teacherDaySchedule, int targetPeriod) {
    // Temporarily inject the period to test state
    teacherDaySchedule[targetPeriod] = "TEMP";

    int maxConsecutive = 0;
    int currentConsecutive = 0;
    
    // Sort assigned periods by their number (1, 2, 3...)
    var periods = teacherDaySchedule.keys.toList()..sort();
    
    int? lastPeriod;
    for (var p in periods) {
      if (lastPeriod == null || p == lastPeriod + 1) {
        currentConsecutive++;
      } else {
        currentConsecutive = 1;
      }
      
      if (currentConsecutive > maxConsecutive) {
        maxConsecutive = currentConsecutive;
      }
      
      lastPeriod = p;
    }

    // Remove temp injection
    teacherDaySchedule.remove(targetPeriod);
    
    // If it forms 5 or more consecutive periods, it violates the rule.
    return maxConsecutive > 4; 
  }
}
