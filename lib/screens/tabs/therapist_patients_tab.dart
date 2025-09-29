import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class TherapistPatientsTab extends StatefulWidget {
  const TherapistPatientsTab({super.key});

  @override
  State<TherapistPatientsTab> createState() => _TherapistPatientsTabState();
}

class _TherapistPatientsTabState extends State<TherapistPatientsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    // Mock data - replace with real API calls
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _patients = [
        {
          'id': '1',
          'name': 'John Doe',
          'age': 32,
          'avatar': null,
          'condition': 'Anxiety, Depression',
          'status': 'active',
          'lastSession': DateTime.now().subtract(const Duration(days: 3)),
          'nextSession': DateTime.now().add(const Duration(hours: 2)),
          'sessionsCount': 8,
          'phone': '+1 234 567 8900',
          'email': 'john.doe@email.com',
          'emergencyContact': 'Jane Doe - +1 234 567 8901',
        },
        {
          'id': '2',
          'name': 'Sarah Smith',
          'age': 28,
          'avatar': null,
          'condition': 'Stress Management',
          'status': 'active',
          'lastSession': DateTime.now().subtract(const Duration(days: 1)),
          'nextSession': DateTime.now().add(const Duration(hours: 4)),
          'sessionsCount': 12,
          'phone': '+1 234 567 8902',
          'email': 'sarah.smith@email.com',
          'emergencyContact': 'Mike Smith - +1 234 567 8903',
        },
        {
          'id': '3',
          'name': 'Mike Johnson',
          'age': 45,
          'avatar': null,
          'condition': 'PTSD',
          'status': 'inactive',
          'lastSession': DateTime.now().subtract(const Duration(days: 14)),
          'nextSession': null,
          'sessionsCount': 15,
          'phone': '+1 234 567 8904',
          'email': 'mike.johnson@email.com',
          'emergencyContact': 'Linda Johnson - +1 234 567 8905',
        },
        {
          'id': '4',
          'name': 'Emily Davis',
          'age': 24,
          'avatar': null,
          'condition': 'Social Anxiety',
          'status': 'active',
          'lastSession': DateTime.now().subtract(const Duration(days: 7)),
          'nextSession': DateTime.now().add(const Duration(days: 2)),
          'sessionsCount': 5,
          'phone': '+1 234 567 8906',
          'email': 'emily.davis@email.com',
          'emergencyContact': 'Robert Davis - +1 234 567 8907',
        },
      ];
      _filteredPatients = _patients;
      _isLoading = false;
    });
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients
            .where(
              (patient) =>
                  patient['name'].toLowerCase().contains(query.toLowerCase()) ||
                  patient['condition'].toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'My Patients',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : Column(
              children: [
                _buildSearchBar(),
                _buildStatsRow(),
                Expanded(child: _buildPatientsList()),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _filterPatients,
        decoration: InputDecoration(
          hintText: 'Search patients...',
          hintStyle: const TextStyle(color: AppTheme.secondaryText),
          prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterPatients('');
                  },
                  icon: const Icon(Icons.clear, color: AppTheme.secondaryText),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryGreen,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final activePatients = _patients
        .where((p) => p['status'] == 'active')
        .length;
    final inactivePatients = _patients
        .where((p) => p['status'] == 'inactive')
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatChip('Total: ${_patients.length}', AppTheme.primaryGreen),
          const SizedBox(width: 12),
          _buildStatChip('Active: $activePatients', const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _buildStatChip(
            'Inactive: $inactivePatients',
            const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPatientsList() {
    if (_filteredPatients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.secondaryText),
            SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(fontSize: 18, color: AppTheme.secondaryText),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadPatients,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];
          return _buildPatientCard(patient);
        },
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final status = patient['status'] as String;
    final isActive = status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPatientDetails(patient),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryGreen.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage: patient['avatar'] != null
                            ? NetworkImage(patient['avatar'])
                            : null,
                        child: patient['avatar'] == null
                            ? const Icon(
                                Icons.person,
                                color: AppTheme.primaryGreen,
                                size: 28,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFF6B7280),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                patient['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                            ),
                            Text(
                              '${patient['age']} years',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patient['condition'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sessions: ${patient['sessionsCount']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Last: ${_formatDate(patient['lastSession'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (patient['nextSession'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_available,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Next session: ${_formatDateTime(patient['nextSession'])}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${difference}d ago';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    String dateStr;
    if (appointmentDay == today) {
      dateStr = 'Today';
    } else if (appointmentDay == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}';
    }

    final timeStr = _formatTime(dateTime);
    return '$dateStr at $timeStr';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient['name'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${patient['age']} years old',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection('Condition', patient['condition']),
                    _buildDetailSection(
                      'Sessions Completed',
                      '${patient['sessionsCount']} sessions',
                    ),
                    _buildDetailSection(
                      'Last Session',
                      _formatDate(patient['lastSession']),
                    ),
                    if (patient['nextSession'] != null)
                      _buildDetailSection(
                        'Next Session',
                        _formatDateTime(patient['nextSession']),
                      ),
                    _buildDetailSection('Phone', patient['phone']),
                    _buildDetailSection('Email', patient['email']),
                    _buildDetailSection(
                      'Emergency Contact',
                      patient['emergencyContact'],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Start video session
                            },
                            icon: const Icon(Icons.videocam),
                            label: const Text('Start Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Send message
                            },
                            icon: const Icon(Icons.message),
                            label: const Text('Message'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                              side: const BorderSide(
                                color: AppTheme.primaryGreen,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 16, color: AppTheme.primaryText),
          ),
        ],
      ),
    );
  }
}
