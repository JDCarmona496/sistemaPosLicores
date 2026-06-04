import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/supabase_config.dart';
import 'config/router.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseConfig.initialize();
  
  runApp(
    const ProviderScope(
      child: LicoreriaApp(),
    ),
  );
}

class LicoreriaApp extends StatelessWidget {
  const LicoreriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Licorería',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
