import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import '../models/onboarding_data.dart';
import 'patient_details_screen.dart';
import 'login_screen.dart';

class PatientOnboardingScreen extends StatefulWidget {
  const PatientOnboardingScreen({super.key});

  @override
  State<PatientOnboardingScreen> createState() =>
      _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<PatientOnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<OnboardingData> onboardingData = [
    OnboardingData(
      title: "Welcome to MindNest",
      subtitle: "Your safe space for mental wellness",
      description:
          "Connect with licensed therapists, track your mood, and access tools designed to support your mental health journey.",
      icon: Icons.favorite,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    OnboardingData(
      title: "Find Your Therapist",
      subtitle: "Professional support when you need it",
      description:
          "Browse profiles of qualified mental health professionals and find the perfect match for your unique needs and preferences.",
      icon: Icons.psychology,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    OnboardingData(
      title: "Track Your Progress",
      subtitle: "Monitor your mental wellness journey",
      description:
          "Use our mood tracking tools, set wellness goals, and celebrate your progress with insightful analytics and achievements.",
      icon: Icons.trending_up,
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    ),
    OnboardingData(
      title: "24/7 Support",
      subtitle: "Help is always available",
      description:
          "Access crisis resources, emergency contacts, and our support community whenever you need help or encouragement.",
      icon: Icons.support_agent,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
  ];

  void _nextPage() {
    if (currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Check if user_onboarding record exists and update/create appropriately
        try {
          final existingOnboarding = await Supabase.instance.client
              .from('user_onboarding')
              .select('id, onboarding_type')
              .eq('user_id', user.id)
              .maybeSingle();

          if (existingOnboarding != null) {
            // Update existing record
            await Supabase.instance.client
                .from('user_onboarding')
                .update({
                  'current_step': 'details_screen',
                  'progress_percentage': 85,
                  'user_type_selected': true,
                  'account_created': true,
                  'onboarding_1_completed': true,
                  'onboarding_2_completed': true,
                  'onboarding_3_completed': true,
                  'onboarding_4_completed': true,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('user_id', user.id);
          } else {
            // Insert new record if it doesn't exist
            await Supabase.instance.client.from('user_onboarding').insert({
              'user_id': user.id,
              'onboarding_type': 'patient',
              'current_step': 'details_screen',
              'progress_percentage': 85,
              'user_type_selected': true,
              'account_created': true,
              'onboarding_1_completed': true,
              'onboarding_2_completed': true,
              'onboarding_3_completed': true,
              'onboarding_4_completed': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (onboardingError) {
          debugPrint('Error updating onboarding progress: $onboardingError');
          // Don't fail the entire flow if onboarding update fails
        }
      }
    } catch (e) {
      debugPrint('Error updating onboarding progress: $e');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        CustomPageTransitions.fadeTransition<void>(PatientDetailsScreen()),
      );
    }
  }

  void _showExitOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete Setup Later?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can finish setting up your patient profile anytime. What would you like to do?',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Cancel Setup Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _cancelSignup(),
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('Cancel Setup & Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7280),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue Setup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelSignup() async {
    Navigator.pop(context); // Close the modal

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CustomPageTransitions.slideFromRight<void>(const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CustomPageTransitions.slideFromRight<void>(const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: currentPage > 0 ? _previousPage : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: currentPage > 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: currentPage > 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: currentPage > 0
                            ? Color(0xFF6B7280)
                            : Colors.transparent,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        onboardingData.length,
                        (index) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentPage == index
                                ? onboardingData[currentPage].gradient.first
                                : Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showExitOptions,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    currentPage = page;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: data.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: data.gradient.first.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(data.icon, color: Colors.white, size: 60),
                        ),
                        SizedBox(height: 48),

                        // Title
                        Text(
                          data.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),

                        // Subtitle
                        Text(
                          data.subtitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: data.gradient.first,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),

                        // Description
                        Text(
                          data.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom button
            Padding(
              padding: EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: onboardingData[currentPage].gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    currentPage == onboardingData.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
