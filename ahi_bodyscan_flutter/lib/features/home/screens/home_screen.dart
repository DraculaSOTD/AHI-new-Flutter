import '../../../core/services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/profile_service.dart';
import '../../../models/user_profile.dart';
import '../../profile/widgets/profile_card.dart';
import '../../profile/widgets/add_profile_card.dart';
import '../../../src/ahi_turnkey_launchers/tk_finger_scan_launcher.dart';
import '../../scanning/launchers/ahi_body_scan_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileService _profileService = ProfileService();
  
  @override
  void initState() {
    super.initState();
    _initializeProfiles();
  }
  
  Future<void> _initializeProfiles() async {
    await _profileService.initialize();
    await _profileService.ensureMainProfile();
    if (mounted) setState(() {});
  }
  
  void _handleSelectProfile(UserProfile profile) async {
    await _profileService.selectProfile(profile);
    if (mounted) setState(() {});
  }
  
  void _handleAddProfile() {
    context.push('/profile/create');
  }
  
  void _handleEditProfile(UserProfile profile) {
    context.push('/profile/edit', extra: profile);
  }
  
  void _handleDeleteProfile(UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete ${profile.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _profileService.deleteProfile(profile.id);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${profile.name} deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting profile: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _launchBodyScan(BuildContext context) {
    // Route through the AHI Turnkey-backed launcher — TkBodyScanLauncher pushed
    // TkNativeScanningPage which sits stuck on "Launching native scanner…"
    // whenever the underlying method-channel call hangs. AHIBodyScanLauncher
    // talks to AHITurnkey.instance directly and surfaces errors as dialogs.
    AHIBodyScanLauncher.launch(context, isPartOfAssessment: false);
  }

  void _launchFaceScan(BuildContext context) {
    context.push('/scan/face/preparation');
  }

  void _launchFingerScan(BuildContext context) {
    final launcher = TkFingerScanLauncher(
      exitPressed: () {
        // Handle exit - could navigate back to home or show success message
      },
    );
    launcher.launch(context);
  }

  void _showNoProfileDialog(BuildContext context, String scanType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile Required'),
        content: Text('Please create and select a profile before starting a $scanType.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAddProfile();
            },
            child: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('AHI BodyScan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                boxShadow: [AppShadows.large],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready for your health assessment?',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textWhite.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/new-scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundWhite,
                      foregroundColor: AppColors.primaryPurple,
                    ),
                    child: const Text('Start New Scan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Profiles section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profiles',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_profileService.hasProfiles)
                  TextButton.icon(
                    onPressed: () => context.push('/profiles'),
                    icon: const Icon(Icons.manage_accounts, size: 16),
                    label: const Text('Manage'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryPurple,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Profiles horizontal scroll
            ListenableBuilder(
              listenable: _profileService,
              builder: (context, child) {
                if (!_profileService.isLoaded) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (!_profileService.hasProfiles) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No profiles yet',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add a profile to start tracking health metrics',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _handleAddProfile,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Profile'),
                        ),
                      ],
                    ),
                  );
                }
                
                return SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: _profileService.profiles.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      if (index == _profileService.profiles.length) {
                        return SizedBox(
                          width: 280,
                          child: AddProfileCard(
                            onTap: _handleAddProfile,
                          ),
                        );
                      }
                      
                      final profile = _profileService.profiles[index];
                      return SizedBox(
                        width: 280,
                        child: ProfileCard(
                          profile: profile,
                          isSelected: _profileService.selectedProfile?.id == profile.id,
                          onTap: () => _handleSelectProfile(profile),
                          onEdit: () => _handleEditProfile(profile),
                          onDelete: profile.isMainProfile ? null : () => _handleDeleteProfile(profile),
                          hasHealthAssessment: false, // TODO: Check for health assessments
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Health Assessment Card
            _buildHealthAssessmentCard(),

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Quick Actions',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = 2;
                final cardWidth = (constraints.maxWidth - 16) / crossAxisCount;
                
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildActionCard(
                        icon: Icons.face,
                        title: 'Face Scan',
                        subtitle: 'Vitals check',
                        color: AppColors.primaryPurple,
                        onTap: () => _launchFaceScan(context),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildActionCard(
                        icon: Icons.accessibility_new,
                        title: 'Body Scan',
                        subtitle: 'Measurements',
                        color: AppColors.secondaryBlue,
                        onTap: () => _launchBodyScan(context),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildActionCard(
                        icon: Icons.assessment,
                        title: 'Reports',
                        subtitle: 'View history',
                        color: AppColors.info,
                        onTap: () => context.go('/reports'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Recent scans
            Text(
              'Recent Scans',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: AppColors.textTertiary,
                  ),
                ),
                title: Text(
                  'No recent scans',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                subtitle: Text(
                  'Start a new scan to see results here',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthAssessmentCard() {
    LoggingService.debug('Building Health Assessment Card', tag: 'HomeScreen');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryBlue,
            AppColors.primaryPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [AppShadows.large],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Check if profile exists
            if (_profileService.selectedProfile == null) {
              _showNoProfileDialog(context, 'Health Assessment');
              return;
            }
            // Launch Health Assessment
            context.push('/health-assessment/disclaimer');
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Health Assessment',
                        style: AppTypography.headingSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comprehensive mental & physical health evaluation',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '30-40 minutes',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}