import 'package:flutter/material.dart';
import '../utils/page_transitions.dart';
import 'signup_screen.dart';
import '../utils/logo_widget.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen>
    with TickerProviderStateMixin {
  String? selectedUserType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
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
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(child: LogoWidget(size: 64)),
                      SizedBox(height: 32),

                      // Welcome text
                      Text(
                        'Join MindNest',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choose how you\'d like to use our platform',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),

                      // User Type Selection Cards
                      _buildUserTypeCard(
                        userType: 'patient',
                        title: 'I need support',
                        subtitle: 'Connect with mental health professionals',
                        icon: Icons.person,
                      ),
                      SizedBox(height: 16),

                      _buildUserTypeCard(
                        userType: 'therapist',
                        title: 'I provide support',
                        subtitle: 'Help others on their mental health journey',
                        icon: Icons.psychology,
                      ),
                      SizedBox(height: 32),

                      // Continue Button
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: selectedUserType != null
                              ? LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: selectedUserType == null
                              ? Color(0xFFE5E7EB)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: selectedUserType != null
                              ? [
                                  BoxShadow(
                                    color: Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: selectedUserType != null
                              ? _proceedToSignup
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              color: selectedUserType != null
                                  ? Colors.white
                                  : Color(0xFF9CA3AF),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Already have account link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String userType,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = selectedUserType == userType;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Color(0xFF10B981) : Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectUserType(userType),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
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
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Color(0xFF10B981) : Color(0xFFE5E7EB),
                      width: 2,
                    ),
                    color: isSelected ? Color(0xFF10B981) : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
