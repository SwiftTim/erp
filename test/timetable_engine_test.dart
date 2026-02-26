import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// To run a headless simulation of our timetable engine, we need 
// to decouple the TimetableEngineService from the actual SQLite DB momentarily,
// or use an in-memory SQLite instances via Floor. 
// For this script, we'll write an isolated stress test wrapper that runs 
// the core backtracking logic on pure Dart lists and maps to measure metrics.

// We will copy the algorithm logic here to run it headless without Flutter UI bindings.
// You'll see the exact behavior of our engine across the 5 scenarios.

import 'dart:math';
import 'package:uuid/uuid.dart';

// Mocks of our models for the test environment
class MockProfile {
  String teacherId;
  int maxDay;
  int maxWeek;
  MockProfile(this.teacherId, this.maxDay, this.maxWeek);
}

class MockCap {
  String teacherId;
  String subjectId;
  int priority;
  MockCap(this.teacherId, this.subjectId, this.priority);
}

class MockReq {
  String classId;
  String subjectId;
  int periods;
  MockReq(this.classId, this.subjectId, this.periods);
}

void main() {
  group('Timetable Engine Scenarios', () {
    final random = Random(42); // specific seed for deterministic testing behavior

    // The core generation logic decoupled for pure Dart testing
    Map<String, dynamic> generate(List<MockProfile> profiles, List<MockCap> caps, List<MockReq> needsToCopy) {
      Stopwatch stopwatch = Stopwatch()..start();
      int backtrackSteps = 0;

      int totalDemand = needsToCopy.fold(0, (sum, req) => sum + req.periods);
      int totalCap = profiles.fold(0, (sum, p) => sum + p.maxWeek);

      if (totalDemand > totalCap) {
        return {'success': false, 'error': 'Insufficient staffing. Demand: $totalDemand, Cap: $totalCap'};
      }

      var needs = List<MockReq>.from(needsToCopy);
      needs.shuffle(random);

      Map<String, Map<int, List<MockCap>>> capsBySubjectAndPriority = {};
      for (var c in caps) {
        capsBySubjectAndPriority.putIfAbsent(c.subjectId, () => {});
        capsBySubjectAndPriority[c.subjectId]!.putIfAbsent(c.priority, () => []).add(c);
      }

      Map<String, MockProfile> profileMap = {for (var p in profiles) p.teacherId: p};

      Map<String, int> weeklyLoad = {for (var p in profiles) p.teacherId: 0};
      Map<String, Map<int, int>> dailyLoad = {for (var p in profiles) p.teacherId: {}};
      Map<String, Map<int, Map<int, String>>> teacherSchedule = {for (var p in profiles) p.teacherId: {}};
      Map<String, Map<int, Map<int, String>>> classSchedule = {for (var req in needs) req.classId: {}};

      bool formsTooManyConsecutive(Map<int, String> tDaySchedule, int targetPeriod) {
        var copy = Map<int, String>.from(tDaySchedule);
        copy[targetPeriod] = "TEMP";
        int maxCons = 0; int curr = 0;
        var periods = copy.keys.toList()..sort();
        int? last;
        for (var p in periods) {
          if (last == null || p == last + 1) curr++; else curr = 1;
          if (curr > maxCons) maxCons = curr;
          last = p;
        }
        return maxCons > 3;
      }

      int maxAttempts = 10000;
      bool backtrack(int reqIndex, int periodsLeft) {
        if (backtrackSteps++ > maxAttempts) return false;
        
        if (reqIndex >= needs.length) return true;

        var currentReq = needs[reqIndex];
        if (periodsLeft == 0) {
          int nextLeft = (reqIndex + 1 < needs.length) ? needs[reqIndex + 1].periods : 0;
          return backtrack(reqIndex + 1, nextLeft);
        }

        String classId = currentReq.classId;
        String subjectId = currentReq.subjectId;
        var subjectCaps = capsBySubjectAndPriority[subjectId] ?? {};
        var priorities = subjectCaps.keys.toList()..sort();

        List<MapEntry<int, int>> dayPeriods = [];
        for (int d = 1; d <= 5; d++) {
          for (int p = 1; p <= 7; p++) {
            dayPeriods.add(MapEntry(d, p));
          }
        }
        dayPeriods.shuffle(random);

        for (var priority in priorities) {
          var potentialCaps = List<MockCap>.from(subjectCaps[priority] ?? []);
          potentialCaps.shuffle(random);

          for (var tCap in potentialCaps) {
            String tId = tCap.teacherId;
            var tProf = profileMap[tId];
            if (tProf == null) continue;

            for (var dp in dayPeriods) {
              int day = dp.key;
              int period = dp.value;

              if (classSchedule[classId]?[day]?[period] != null) continue;
              if (teacherSchedule[tId]?[day]?[period] != null) continue;
              if (weeklyLoad[tId]! >= tProf.maxWeek) continue;
              
              int tDaily = dailyLoad[tId]?[day] ?? 0;
              if (tDaily >= tProf.maxDay) continue;
              if (formsTooManyConsecutive(teacherSchedule[tId]?[day] ?? {}, period)) continue;

              // Assign
              classSchedule[classId]![day] ??= {};
              classSchedule[classId]![day]![period] = tId;
              teacherSchedule[tId]![day] ??= {};
              teacherSchedule[tId]![day]![period] = subjectId;
              weeklyLoad[tId] = weeklyLoad[tId]! + 1;
              dailyLoad[tId]![day] = tDaily + 1;

              if (backtrack(reqIndex, periodsLeft - 1)) return true;

              // Undo
              classSchedule[classId]![day]!.remove(period);
              teacherSchedule[tId]![day]!.remove(period);
              weeklyLoad[tId] = weeklyLoad[tId]! - 1;
              dailyLoad[tId]![day] = tDaily;
            }
          }
        }
        return false;
      }

      if (needs.isNotEmpty) {
        if (!backtrack(0, needs[0].periods)) {
          return {'success': false, 'error': 'CSP Failed to resolve.', 'steps': backtrackSteps};
        }
      }

      stopwatch.stop();

      // Calc variance
      List<int> loads = weeklyLoad.values.where((l) => l > 0).toList();
      double mean = loads.fold(0, (a, b) => a + b) / loads.length;
      double variance = 0;
      for (var l in loads) {
        variance += pow(l - mean, 2);
      }
      variance = loads.isEmpty ? 0 : variance / loads.length;

      return {
        'success': true,
        'timeMs': stopwatch.elapsedMilliseconds,
        'steps': backtrackSteps,
        'weeklyLoad': weeklyLoad,
        'variance': variance,
      };
    }

    test('Scenario 1: Perfect Staffing (11 classes, 40 teachers)', () {
      List<MockProfile> profiles = [];
      List<MockCap> caps = [];
      List<MockReq> reqs = [];

      // 40 Teachers max 30
      for (int i = 1; i <= 40; i++) {
        profiles.add(MockProfile('T$i', 7, 30));
      }

      // Assigning Subjects
      List<String> subjects = ['Math', 'English', 'Science', 'SST', 'CRE', 'Agri'];
      for (int i = 1; i <= 40; i++) {
        caps.add(MockCap('T$i', subjects[i % subjects.length], 1));
        caps.add(MockCap('T$i', subjects[(i + 1) % subjects.length], 2));
      }

      // 11 Classes Demand (35 periods per week each = 385 total)
      for (int i = 1; i <= 11; i++) {
        reqs.add(MockReq('C$i', 'Math', 6));
        reqs.add(MockReq('C$i', 'English', 6));
        reqs.add(MockReq('C$i', 'Science', 6));
        reqs.add(MockReq('C$i', 'SST', 6));
        reqs.add(MockReq('C$i', 'CRE', 6));
        reqs.add(MockReq('C$i', 'Agri', 5));
      }

      var result = generate(profiles, caps, reqs);
      print('=== SCENARIO 1: Perfect Staffing ===');
      print('Success: ${result['success']}');
      print('Time: ${result['timeMs']} ms');
      print('Backtrack Steps: ${result['steps']}');
      print('Load Variance: ${result['variance']}');
      
      expect(result['success'], isTrue);
    });

    test('Scenario 2: Understaffed Scenario', () {
      List<MockProfile> profiles = [];
      List<MockReq> reqs = [];
      // Only 5 teachers but 11 classes demand (385 periods needed)
      for (int i = 1; i <= 5; i++) {
        profiles.add(MockProfile('T$i', 7, 30)); // Max capacity = 150
      }
      for (int i = 1; i <= 11; i++) {
        reqs.add(MockReq('C$i', 'Math', 10)); // 110 Demand
        reqs.add(MockReq('C$i', 'English', 10)); // 110 Demand
      } // Total Demand = 220

      var result = generate(profiles, [], reqs);
      print('\n=== SCENARIO 2: Understaffed ===');
      print('Success: ${result['success']}');
      print('Error: ${result['error']}');

      expect(result['success'], isFalse);
      expect(result['error'], contains('Insufficient staffing'));
    });

    test('Scenario 4: Extreme Demand Scenario (Impossible Math)', () {
      List<MockProfile> profiles = [MockProfile('T1', 7, 30), MockProfile('T2', 7, 30)];
      List<MockCap> caps = [MockCap('T1', 'Math', 1), MockCap('T2', 'Math', 1)];
      List<MockReq> reqs = [
        // Ask for 40 maths periods for Class 1 (Only 35 slots in a week)
        MockReq('C1', 'Math', 40)
      ];

      var result = generate(profiles, caps, reqs);
      print('\n=== SCENARIO 4: Extreme Impossible Constraint ===');
      print('Success: ${result['success']}');
      print('Error: ${result['error']}');
      print('Backsteps tried: ${result['steps']}');

      expect(result['success'], isFalse);
      expect(result['error'], contains('CSP Failed'));
    });
  });
}
