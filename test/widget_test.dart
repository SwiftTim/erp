// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cbc_school/main.dart';

void main() {
  testWidgets('App smoke test - launches login page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CbcSchoolApp()));
    await tester.pumpAndSettle();
    // Should show the login form
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
