import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';
import '../../utils/user_profile_helper.dart';

class TherapistHomeTab extends StatefulWidget {
  const TherapistHomeTab({super.key});

  @override
  State<TherapistHomeTab> createState() => _TherapistHomeTabState();
}

class _TherapistHomeTabState extends State<TherapistHomeTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _therapistData;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  Map<String, int> _dashboardStats = {
    'totalPatients': 0,
    'upcomingAppointments': 0,
    'completedSessions': 0,
    'pendingRequests': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load therapist data
      final therapistData = await Supabase.instance.client
          .from('therapists')
          .select('first_name, last_name, specialization, profile_pic_url')
          .eq('id', user.id)
          .maybeSingle();

      // Load upcoming appointments (mock data for now)
      // TODO: Replace with real appointments when appointment system is implemented
      final upcomingAppointments = [
        {
          'patient_name': 'John Doe',
          'time': DateTime.now().add(Duration(hours: 2)),
          'type': 'Initial Consultation',
          'status': 'confirmed',
        },
        {
          'patient_name': 'Sarah Smith',
          'time': DateTime.now().add(Duration(hours: 4)),
          'type': 'Follow-up Session',
          'status': 'confirmed',
        },
      ];

      setState(() {
        _therapistData = therapistData;
        _upcomingAppointments = upcomingAppointments;
        _dashboardStats = {
          'totalPatients': 12,
          'upcomingAppointments': upcomingAppointments.length,
          'completedSessions': 45,
          'pendingRequests': 3,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : RefreshIndicator(
                color: AppTheme.primaryGreen,
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeHeader(),
                      const SizedBox(height: 24),
                      _buildStatsCards(),
                      const SizedBox(height: 24),
                      _buildUpcomingAppointments(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return FutureBuilder<String>(
      future: UserProfileHelper.getUserFirstName(),
      builder: (context, snapshot) {
        final firstName =
            snapshot.data ?? (_therapistData?['first_name'] ?? 'Therapist');

        final specializations =
            (_therapistData?['specialization'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
        final primarySpecialization = specializations.isNotEmpty
            ? specializations.first
            : 'Mental Health Professional';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: _therapistData?['profile_pic_url'] != null
                    ? NetworkImage(_therapistData!['profile_pic_url'])
                    : null,
                child: _therapistData?['profile_pic_url'] == null
                    ? const Icon(Icons.person, color: Colors.white, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getTimeOfDayGreeting()}, Dr. $firstName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      primarySpecialization,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to help your patients today?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Patients',
          _dashboardStats['totalPatients'].toString(),
          Icons.people,
          const Color(0xFF3B82F6),
        ),
        _buildStatCard(
          'Today\'s Sessions',
          _dashboardStats['upcomingAppointments'].toString(),
          Icons.calendar_today,
          const Color(0xFF10B981),
        ),
        _buildStatCard(
          'Completed Sessions',
          _dashboardStats['completedSessions'].toString(),
          Icons.check_circle,
          const Color(0xFF8B5CF6),
        ),
        _buildStatCard(
          'Pending Requests',
          _dashboardStats['pendingRequests'].toString(),
          Icons.pending_actions,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Appointments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        if (_upcomingAppointments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: AppTheme.secondaryText,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No appointments scheduled for today',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_upcomingAppointments.map(
            (appointment) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['patient_name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment['type'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(appointment['time']),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildQuickActionCard(
              'Schedule Session',
              Icons.schedule,
              const Color(0xFF3B82F6),
              () {},
            ),
            _buildQuickActionCard(
              'Patient Notes',
              Icons.note_add,
              const Color(0xFF8B5CF6),
              () {},
            ),
            _buildQuickActionCard(
              'View Reports',
              Icons.analytics,
              const Color(0xFF10B981),
              () {},
            ),
            _buildQuickActionCard(
              'Messages',
              Icons.message,
              const Color(0xFFF59E0B),
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
