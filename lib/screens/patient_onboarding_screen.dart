import 'package:flutter/material.dart';
import '../utils/page_transitions.dart';
import '../models/onboarding_data.dart';
import 'patient_details_screen.dart';

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

  void _completeOnboarding() {
    Navigator.of(context).pushReplacement(
      CustomPageTransitions.fadeTransition<void>(PatientDetailsScreen()),
    );
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
                    onTap: currentPage < onboardingData.length - 1
                        ? () => _pageController.animateToPage(
                            onboardingData.length - 1,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                        : null,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: currentPage < onboardingData.length - 1
                            ? Color(0xFF6B7280)
                            : Colors.transparent,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
