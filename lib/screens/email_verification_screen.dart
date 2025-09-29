import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/ui_helpers.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String userType; // 'patient' or 'therapist'

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.userType,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes to detect when email is verified
    _listenForVerification();
  }

  void _listenForVerification() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn &&
          data.session?.user.emailConfirmedAt != null) {
        debugPrint('Email verified successfully!');
        // The main.dart auth listener will handle navigation
      }
    });
  }

  Future<void> resendVerificationEmail() async {
    setState(() {
      isResending = true;
    });

    try {
      await Supabase.instance.client.auth
          .resend(
            type: OtpType.signup,
            email: widget.email,
            emailRedirectTo: 'io.supabase.mindnest://login-callback/',
          )
          .timeout(Duration(seconds: 10));

      _showMessage(
        'Verification email sent! Please check your inbox and spam folder.',
        isError: false,
      );
    } on AuthException catch (error) {
      debugPrint('Resend error: ${error.message}');
      _showMessage('Failed to resend email: ${error.message}');
    } catch (error) {
      debugPrint('Resend timeout/error: $error');
      _showMessage(
        'Network error. Please check your connection and try again.',
      );
    } finally {
      setState(() {
        isResending = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    UIHelpers.showMessage(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).viewPadding.top -
                  MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Email icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Check your email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description with proper overflow handling
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'We sent a verification link to\n',
                          ),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const TextSpan(
                            text:
                                '\n\nClick the link in your email to verify your account and continue with your ',
                          ),
                          TextSpan(
                            text: widget.userType,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' registration.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Resend email button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isResending ? null : resendVerificationEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                      ),
                      child: isResending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Resend verification email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Help text with proper overflow handling
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Didn\'t receive the email? Check your spam folder or try resending.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Back to login button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Back to Sign In',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
