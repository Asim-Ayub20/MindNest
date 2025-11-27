import 'package:flutter/material.dart';
import '../models/therapist.dart';
import '../utils/app_theme.dart';

class TherapistCard extends StatelessWidget {
  final Therapist therapist;
  final VoidCallback? onTap;
  final bool showBookingButton;

  const TherapistCard({
    super.key,
    required this.therapist,
    this.onTap,
    this.showBookingButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with profile pic, name, and verification badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfilePicture(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                therapist.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                            ),
                            // TODO: Add verification badge when verification system is implemented
                            // if (therapist.isVerified)
                            //   Container(...)
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          therapist.displayLocation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Specializations
              if (therapist.specializations.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: therapist.specializations.take(3).map((spec) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        spec,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Bio preview (if available)
              if (therapist.bio != null && therapist.bio!.isNotEmpty) ...[
                Text(
                  therapist.bio!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryText,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Stats row
              Row(
                children: [
                  // Experience (instead of rating)
                  _buildStatItem(
                    icon: Icons.work_outline,
                    iconColor: AppTheme.primaryGreen,
                    label: therapist.experienceText,
                  ),
                  const SizedBox(width: 16),

                  // Experience
                  _buildStatItem(
                    icon: Icons.work,
                    iconColor: AppTheme.primaryGreen,
                    label: therapist.experienceText,
                  ),

                  const Spacer(),

                  // Fee
                  Text(
                    therapist.feeText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),

              // Booking button (if enabled)
              if (showBookingButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to booking screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking feature coming soon!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Book Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.lightGreen.withValues(alpha: 0.1),
        border: Border.all(
          color: AppTheme.lightGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: therapist.hasProfilePic
          ? ClipOval(
              child: Image.network(
                therapist.profilePicUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildDefaultAvatar();
                },
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 30,
      color: AppTheme.primaryGreen.withValues(alpha: 0.6),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Compact version of therapist card for lists
class TherapistCompactCard extends StatelessWidget {
  final Therapist therapist;
  final VoidCallback? onTap;

  const TherapistCompactCard({super.key, required this.therapist, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Profile picture
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightGreen.withValues(alpha: 0.1),
                ),
                child: therapist.hasProfilePic
                    ? ClipOval(
                        child: Image.network(
                          therapist.profilePicUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 24,
                              color: AppTheme.primaryGreen,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 24,
                        color: AppTheme.primaryGreen,
                      ),
              ),

              const SizedBox(width: 12),

              // Name and specialization
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      therapist.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      therapist.primarySpecialization,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // Experience instead of rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.work,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${therapist.experienceYears}y',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.secondaryText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
