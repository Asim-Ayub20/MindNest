import 'package:flutter/material.dart';
import '../utils/page_transitions.dart';
import '../models/onboarding_data.dart';
import 'home_screen.dart';

class TherapistOnboardingScreen extends StatefulWidget {
  const TherapistOnboardingScreen({super.key});

  @override
  State<TherapistOnboardingScreen> createState() =>
      _TherapistOnboardingScreenState();
}

class _TherapistOnboardingScreenState extends State<TherapistOnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<OnboardingData> onboardingData = [
    OnboardingData(
      title: "Welcome Provider",
      subtitle: "Join our network of mental health professionals",
      description:
          "Help clients on their mental wellness journey while managing your practice efficiently with our comprehensive platform.",
      icon: Icons.psychology,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    OnboardingData(
      title: "Manage Your Practice",
      subtitle: "Streamlined client and session management",
      description:
          "Keep track of your clients, schedule sessions, manage notes, and handle billing all in one secure, HIPAA-compliant platform.",
      icon: Icons.calendar_today,
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    ),
    OnboardingData(
      title: "Connect with Clients",
      subtitle: "Secure video sessions and messaging",
      description:
          "Conduct therapy sessions through secure video calls and stay connected with clients through encrypted messaging and progress tracking.",
      icon: Icons.video_call,
      gradient: [Color(0xFF8B7CF6), Color(0xFF7C3AED)],
    ),
    OnboardingData(
      title: "Professional Tools",
      subtitle: "Assessment tools and progress tracking",
      description:
          "Access evidence-based assessment tools, track client progress, and generate reports to provide the best possible care.",
      icon: Icons.assessment,
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
    Navigator.of(
      context,
    ).pushReplacement(CustomPageTransitions.fadeTransition<void>(HomeScreen()));
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
                        ? 'Start Helping'
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
