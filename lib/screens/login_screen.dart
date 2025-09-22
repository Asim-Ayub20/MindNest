import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          _showMessage('Please verify your email before logging in');
          return;
        }

        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (error) {
      _showMessage('Login failed: ${error.message}');
    } catch (error) {
      _showMessage('An unexpected error occurred');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Sign In', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signup');
              },
              child: Text('Need an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
