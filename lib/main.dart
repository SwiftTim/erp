import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/data/curriculum_seed.dart';
import 'data/local/app_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase, but don't crash if it fails (missing config)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Operating in offline mode
  }

  // Seed the CBC curriculum (idempotent — skips if already seeded)
  try {
    final db = await AppDatabase.create();
    await seedCurriculum(db);
  } catch (e) {
    // A seed failure must never prevent the app from launching
    debugPrint('Curriculum seed error: $e');
  }

  runApp(const ProviderScope(child: CbcSchoolApp()));
}


class CbcSchoolApp extends ConsumerWidget {
  const CbcSchoolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CBC School',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
