import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yqhgsmrtxgfjuljazoie.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxaGdzbXJ0eGdmanVsamF6b2llIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NTE2ODEsImV4cCI6MjA3NDEyNzY4MX0.Iny6UH4vjesqQyh4sDMcmV58XKgUXDeERImhlKJNcUk',
  );

  runApp(MindNestApp());
}

class MindNestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AuthenticationGate(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class AuthenticationGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final Session? session = snapshot.hasData
            ? snapshot.data!.session
            : null;

        if (session != null) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
