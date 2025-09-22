import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> handleSignup() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'full_name': emailController.text.split('@')[0],
          'role': 'patient',
        },
      );

      if (response.user != null) {
        _showMessage('Account created! Please check your email to verify.');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on AuthException catch (error) {
      _showMessage('Signup failed: ${error.message}');
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
        title: Text('Create Account'),
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
              'Sign Up for MindNest',
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
              onPressed: isLoading ? null : handleSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Create Account', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Already have an account? Sign In'),
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
