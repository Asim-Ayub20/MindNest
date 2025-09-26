import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'journal_screen.dart';
import 'patient_chat_screen.dart';
import 'therapist_chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final String? role = user?.userMetadata?['role'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text('MindNest Home'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => handleLogout(context),
            icon: Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.psychology, size: 80, color: Colors.deepPurple),
            SizedBox(height: 24),
            Text(
              'Welcome to MindNest!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Hello ${user?.email ?? 'User'}',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'You are successfully logged in!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your mental wellness journey starts here.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            // Show only the relevant chat button and journal for patients
            if (role == 'patient') ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PatientChatScreen(
                        therapistName: 'Dr. Smith',
                        therapistAvatarUrl:
                            'https://randomuser.me/api/portraits/men/32.jpg',
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat_bubble_outline),
                label: Text('Chat with Therapist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => JournalScreen()),
                  );
                },
                icon: Icon(Icons.book_rounded),
                label: Text('My Journal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  side: BorderSide(color: Colors.deepPurple, width: 1.2),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            if (role == 'therapist')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TherapistChatScreen(
                        patientName: 'John Doe',
                        patientAvatarUrl:
                            'https://randomuser.me/api/portraits/men/45.jpg',
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat_bubble_outline),
                label: Text('Chat with Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => handleLogout(context),
              icon: Icon(Icons.logout),
              label: Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
