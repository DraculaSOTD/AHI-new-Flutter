import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/profile_service.dart';
import '../../health_assessment/models/health_assessment.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ProfileService _profileService = ProfileService();
  List<HealthAssessment> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh whenever the tab is reactivated. Cheap — reads one SharedPrefs
    // key and decodes the JSON list.
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('assessment_history') ?? [];
      final decoded = <HealthAssessment>[];
      for (final s in raw) {
        try {
          decoded.add(HealthAssessment.fromJsonString(s));
        } catch (e) {
          LoggingService.warning(
            'Skipping malformed assessment_history entry',
            tag: 'ReportsScreen',
            context: {'error': e.toString()},
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _history = decoded;
        _loadingHistory = false;
      });
    } catch (e) {
      LoggingService.error('Failed to load assessment history',
          error: e, tag: 'ReportsScreen');
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Assessment Card (always visible at top)
              _buildHealthAssessmentCard(),

              const SizedBox(height: 32),

              // Scan History Section
              Text(
                'Scan History',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (_loadingHistory)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_history.isEmpty)
                _buildEmptyReportsSection()
              else
                Column(
                  children: _history
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildHistoryCard(a),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HealthAssessment a) {
    final completed = a.completedAt;
    final dateLabel = completed != null
        ? '${completed.year}-${completed.month.toString().padLeft(2, '0')}-${completed.day.toString().padLeft(2, '0')} '
            '${completed.hour.toString().padLeft(2, '0')}:${completed.minute.toString().padLeft(2, '0')}'
        : 'Date unknown';
    final risk = a.overallRiskLevel;
    final Color riskColor;
    switch (risk) {
      case 'critical':
      case 'high':
        riskColor = AppColors.error;
        break;
      case 'moderate':
        riskColor = AppColors.warning;
        break;
      case 'low':
        riskColor = AppColors.success;
        break;
      default:
        riskColor = AppColors.textTertiary;
    }
    final vitals = a.vitalSigns;
    final hr = vitals?.averageHeartRate;
    final bodyFat = a.bodyScanResult?.bodyfatInPercent;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          onTap: () => context.push('/reports/assessment', extra: a),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_turned_in, color: riskColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Health Assessment',
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        risk.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dateLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                if (hr != null || bodyFat != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (hr != null) ...[
                        Icon(Icons.favorite,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${hr.round()} bpm',
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 12),
                      ],
                      if (bodyFat != null) ...[
                        Icon(Icons.accessibility_new,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${bodyFat.toStringAsFixed(1)}% BF',
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthAssessmentCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
              _showNoProfileDialog();
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
                // Icon container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    size: 36,
                    color: Colors.white,
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
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
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
                const Icon(
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

  Widget _buildEmptyReportsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge * 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Scan Reports Yet',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed scans will appear here',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNoProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Profile Selected'),
        content: const Text(
          'Please create or select a profile before starting the Health Assessment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to profile creation/selection
              context.push('/profiles');
            },
            child: const Text('Go to Profiles'),
          ),
        ],
      ),
    );
  }
}
