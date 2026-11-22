import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      home: const ConnectionTest(),
    );
  }
}

class ConnectionTest extends StatelessWidget {
  const ConnectionTest({super.key});

  Future<int> _countBooks() async {
    final rows = await Supabase.instance.client.from('books').select('id');
    return rows.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUVERA')),
      body: Center(
        child: FutureBuilder<int>(
          future: _countBooks(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            if (snap.hasError) {
              return Text('Connection failed:\n${snap.error}');
            }
            return Text(
              'Connected! Books in database: ${snap.data}',
              style: Theme.of(context).textTheme.titleLarge,
            );
          },
        ),
      ),
    );
  }
}