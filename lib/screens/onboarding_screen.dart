import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/page_transitions.dart';
import '../models/onboarding_data.dart';
import 'patient_details_screen.dart';
import 'therapist_data_form_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userType; // 'patient' or 'therapist'

  const OnboardingScreen({super.key, required this.userType});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mental wellness color palette
  static const Color _primaryGreen = Color(0xFF7CB69D);
  static const Color _deepGreen = Color(0xFF5A9A7F);
  static const Color _softCream = Color(0xFFFAF9F6);
  static const Color _warmGray = Color(0xFF6B7280);
  static const Color _darkText = Color(0xFF2D3436);
  static const Color _lightGray = Color(0xFFF3F4F6);

  late final List<OnboardingData> onboardingData;

  @override
  void initState() {
    super.initState();
    _initializeOnboardingData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  void _initializeOnboardingData() {
    if (widget.userType == 'patient') {
      onboardingData = [
        OnboardingData(
          title: "Welcome to MindNest",
          subtitle: "Your sanctuary for mental wellness",
          description:
              "Connect with licensed therapists, track your mood, and access tools designed to support your mental health journey.",
          icon: Icons.spa_outlined,
          gradient: [Color(0xFF7CB69D), Color(0xFF5A9A7F)],
        ),
        OnboardingData(
          title: "Find Your Therapist",
          subtitle: "Professional support when you need it",
          description:
              "Browse profiles of qualified mental health professionals and find the perfect match for your unique needs.",
          icon: Icons.psychology_outlined,
          gradient: [Color(0xFF7CB69D), Color(0xFF5A9A7F)],
        ),
        OnboardingData(
          title: "Track Your Progress",
          subtitle: "Monitor your wellness journey",
          description:
              "Use our mood tracking tools, set wellness goals, and celebrate your progress with insightful analytics.",
          icon: Icons.show_chart_rounded,
          gradient: [Color(0xFF7CB69D), Color(0xFF5A9A7F)],
        ),
        OnboardingData(
          title: "24/7 Support",
          subtitle: "Help is always available",
          description:
              "Access crisis resources, emergency contacts, and our support community whenever you need encouragement.",
          icon: Icons.favorite_outline_rounded,
          gradient: [Color(0xFF7CB69D), Color(0xFF5A9A7F)],
        ),
      ];
    } else {
      onboardingData = [
        OnboardingData(
          title: "Welcome Provider",
          subtitle: "Join our network of professionals",
          description:
              "Help clients on their mental wellness journey while managing your practice efficiently with our comprehensive platform.",
          icon: Icons.psychology_outlined,
          gradient: [Color(0xFF7CB69D), Color(0xFF5A9A7F)],
        ),
        OnboardingData(
          title: "Manage Your Practice",
          subtitle: "Streamlined client management",
          description:
              "Keep track of your clients, schedule sessions, manage notes, and handle billing all in one secure platform.",
          icon: Icons.calendar_today_outlined,
          gradient: [Color(0xFF7CB69D), Color(0xFF5A9A7F)],
        ),
        OnboardingData(
          title: "Connect with Clients",
          subtitle: "Secure sessions and messaging",
          description:
              "Conduct therapy sessions through secure video calls and stay connected with clients through encrypted messaging.",
          icon: Icons.video_call_outlined,
          gradient: [Color(0xFF7CB69D), Color(0xFF5A9A7F)],
        ),
        OnboardingData(
          title: "Professional Tools",
          subtitle: "Assessment and progress tracking",
          description:
              "Access evidence-based assessment tools, track client progress, and generate reports to provide the best care.",
          icon: Icons.insights_outlined,
          gradient: [Color(0xFF7CB69D), Color(0xFF5A9A7F)],
        ),
      ];
    }
  }

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
        try {
          final existingOnboarding = await Supabase.instance.client
              .from('user_onboarding')
              .select('id, onboarding_type')
              .eq('user_id', user.id)
              .maybeSingle();

          if (existingOnboarding != null) {
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
            await Supabase.instance.client.from('user_onboarding').insert({
              'user_id': user.id,
              'onboarding_type': widget.userType,
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
        }
      }
    } catch (e) {
      debugPrint('Error updating onboarding progress: $e');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        CustomPageTransitions.fadeTransition<void>(
          widget.userType == 'patient'
              ? PatientDetailsScreen()
              : TherapistDataFormScreen(),
        ),
      );
    }
  }

  void _showExitOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _softCream,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
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
                color: _warmGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.pause_circle_outline_rounded,
                size: 32,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Complete Setup Later?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: _darkText,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can finish setting up your profile anytime. Your progress will be saved.',
              style: TextStyle(fontSize: 14, color: _warmGray, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Cancel Setup Button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: _warmGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _cancelSignup(),
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Continue Button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryGreen, _deepGreen],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Continue Setup',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelSignup() async {
    Navigator.pop(context);

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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _softCream,
      body: Stack(
        children: [
          // Background decorative elements
          _buildBackgroundDecoration(size),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Header with progress
                    _buildHeader(),

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
                          return _buildOnboardingPage(
                            onboardingData[index],
                            index,
                          );
                        },
                      ),
                    ),

                    // Bottom button
                    _buildBottomButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -size.width * 0.3,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primaryGreen.withValues(alpha: 0.12),
                  _primaryGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -size.width * 0.4,
          left: -size.width * 0.3,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _deepGreen.withValues(alpha: 0.08),
                  _deepGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: currentPage > 0 ? _previousPage : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: currentPage > 0 ? 1.0 : 0.0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _darkText.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _darkText,
                  size: 20,
                ),
              ),
            ),
          ),

          // Progress indicators
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentPage == index ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: currentPage == index
                        ? LinearGradient(colors: [_primaryGreen, _deepGreen])
                        : null,
                    color: currentPage == index ? null : _lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // Menu button
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
                    color: _darkText.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.more_horiz_rounded, color: _warmGray, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data, int index) {
    final emojis = widget.userType == 'patient'
        ? ['🌱', '🧠', '📈', '💚']
        : ['💚', '📅', '🎥', '📊'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryGreen, _deepGreen],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Icon(data.icon, color: Colors.white, size: 44),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            data.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: _darkText,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Subtitle badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${emojis[index]}  ${data.subtitle}',
              style: TextStyle(
                fontSize: 13,
                color: _deepGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _lightGray, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _darkText.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              data.description,
              style: TextStyle(fontSize: 15, color: _warmGray, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLastPage = currentPage == onboardingData.length - 1;
    final buttonText = isLastPage
        ? (widget.userType == 'patient' ? 'Get Started' : 'Start Helping')
        : 'Continue';

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryGreen, _deepGreen],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _nextPage,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastPage
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 22,
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
