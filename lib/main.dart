import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gate.dart';
import 'env.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const AuveraApp());
}

class AuveraApp extends StatelessWidget {
  const AuveraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUVERA',
      debugShowCheckedModeBanner: false,
      theme: auveraLightTheme(),
      home: const AuthGate(),
    );
  }
}
