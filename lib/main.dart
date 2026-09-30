import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const CSUAKioskApp());
}

class CSUAKioskApp extends StatelessWidget {
  const CSUAKioskApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSU-A Kiosk Terminal',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const WelcomeScreen(),
      routes: {'/welcome': (context) => const WelcomeScreen()},
    );
  }
}
