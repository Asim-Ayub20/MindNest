import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class PatientFindTab extends StatelessWidget {
  const PatientFindTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find Your Therapist',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with licensed mental health professionals',
              style: TextStyle(fontSize: 16, color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by specialization, name...',
                  hintStyle: TextStyle(color: AppTheme.lightText),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppTheme.secondaryText),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filter Options
            Row(
              children: [
                Expanded(child: _buildFilterChip('All')),
                const SizedBox(width: 12),
                Expanded(child: _buildFilterChip('Anxiety')),
                const SizedBox(width: 12),
                Expanded(child: _buildFilterChip('Depression')),
              ],
            ),
            const SizedBox(height: 24),

            // Coming Soon Message
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.people,
                        size: 48,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Therapist Directory',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming Soon! We\'re building a comprehensive\ndirectory of verified therapists.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightGreen),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.darkGreen,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
