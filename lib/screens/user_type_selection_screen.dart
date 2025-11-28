import 'package:flutter/material.dart';
import '../utils/page_transitions.dart';
import 'signup_screen.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? selectedUserType;
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

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectUserType(String userType) {
    setState(() {
      selectedUserType = userType;
    });
  }

  void _proceedToSignup() {
    if (selectedUserType == null) return;

    Navigator.of(context).push(
      CustomPageTransitions.slideFromRight<void>(
        SignupScreen(userType: selectedUserType!),
      ),
    );
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: size.height * 0.04),

                          // Logo and branding
                          _buildLogo(),
                          const SizedBox(height: 12),

                          // App name
                          Text(
                            'MindNest',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: _darkText,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Tagline
                          Text(
                            'Your sanctuary for mental wellness',
                            style: TextStyle(
                              fontSize: 13,
                              color: _warmGray,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Welcome message
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '✨  Choose your path',
                              style: TextStyle(
                                fontSize: 13,
                                color: _deepGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // User Type Selection Cards
                          _buildUserTypeCard(
                            userType: 'patient',
                            title: 'I\'m seeking support',
                            subtitle:
                                'Connect with caring professionals who understand',
                            emoji: '🌱',
                          ),
                          const SizedBox(height: 12),

                          _buildUserTypeCard(
                            userType: 'therapist',
                            title: 'I\'m a care provider',
                            subtitle:
                                'Help others on their journey to wellness',
                            emoji: '💚',
                          ),
                          const SizedBox(height: 24),

                          // Continue Button
                          _buildContinueButton(),
                          const SizedBox(height: 20),

                          // Divider with text
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        _warmGray.withValues(alpha: 0.3),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'already a member?',
                                  style: TextStyle(
                                    color: _warmGray.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _warmGray.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Sign in button
                          _buildSignInButton(),
                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
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
        // Top right soft circle
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
                  _primaryGreen.withValues(alpha: 0.15),
                  _primaryGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom left soft circle
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
        // Subtle nature icons
        Positioned(
          top: size.height * 0.15,
          left: 20,
          child: Transform.rotate(
            angle: -0.3,
            child: Icon(
              Icons.eco_outlined,
              size: 24,
              color: _primaryGreen.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.25,
          right: 30,
          child: Transform.rotate(
            angle: 0.5,
            child: Icon(
              Icons.spa_outlined,
              size: 20,
              color: _primaryGreen.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.2,
          left: 40,
          child: Transform.rotate(
            angle: 0.2,
            child: Icon(
              Icons.local_florist_outlined,
              size: 18,
              color: _primaryGreen.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryGreen, _deepGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 36,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String userType,
    required String title,
    required String subtitle,
    required String emoji,
  }) {
    final bool isSelected = selectedUserType == userType;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? _primaryGreen : _lightGray,
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? _primaryGreen.withValues(alpha: 0.15)
                : _darkText.withValues(alpha: 0.04),
            blurRadius: isSelected ? 20 : 10,
            offset: Offset(0, isSelected ? 8 : 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectUserType(userType),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container with gradient
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [_primaryGreen, _deepGreen]
                          : [_lightGray, _lightGray],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: _warmGray,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _primaryGreen : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? _primaryGreen
                          : _warmGray.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final bool isEnabled = selectedUserType != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryGreen, _deepGreen],
              )
            : null,
        color: isEnabled ? null : _lightGray,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _proceedToSignup : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.white
                        : _warmGray.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isEnabled) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryGreen.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              'Sign in instead',
              style: TextStyle(
                color: _deepGreen,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
