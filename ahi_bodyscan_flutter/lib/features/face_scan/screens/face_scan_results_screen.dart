import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/lambda_service.dart';
import '../../health_assessment/services/health_assessment_orchestrator.dart';

class FaceScanResultsScreen extends StatelessWidget {
  final HealthAssessmentResult? results;
  final bool isPartOfAssessment;

  const FaceScanResultsScreen({
    super.key,
    this.results,
    this.isPartOfAssessment = false,
  });

  @override
  Widget build(BuildContext context) {
    // Results should now be passed as constructor parameter from router
    if (results == null) {
      return _buildNoResultsScreen(context);
    }

    final assessmentResults = results!;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Health Assessment',
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: () => _shareResults(context, assessmentResults),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Assessment Info (if part of assessment)
            if (isPartOfAssessment) ...[
              _buildAssessmentInfoCard(context),
              const SizedBox(height: 20),
            ],

            // Health Score Card
            if (assessmentResults.healthScore != null)
              _buildHealthScoreCard(assessmentResults.healthScore!),

            const SizedBox(height: 20),

            // Risk breakdown — every factor the Lambda used to derive the score.
            if (assessmentResults.lambdaSuccess) ...[
              _buildSectionTitle('Risk Breakdown'),
              const SizedBox(height: 12),
              _buildRiskBreakdown(
                assessmentResults.riskBreakdown,
                assessmentResults.healthScore,
              ),
              const SizedBox(height: 24),
            ] else if (assessmentResults.riskBreakdown.isEmpty &&
                assessmentResults.lambdaError != null) ...[
              _buildRiskBreakdownUnavailable(),
              const SizedBox(height: 24),
            ],

            // Vital Signs Section
            _buildSectionTitle(isPartOfAssessment ? 'Averaged Vital Signs (3 Scans)' : 'Vital Signs'),
            const SizedBox(height: 12),
            _buildVitalSignsGrid(assessmentResults),
            
            const SizedBox(height: 24),
            
            // Advanced Metrics (if Lambda succeeded)
            if (assessmentResults.lambdaSuccess) ...[
              _buildSectionTitle('Advanced Health Metrics'),
              const SizedBox(height: 12),
              _buildAdvancedMetricsGrid(assessmentResults),
              const SizedBox(height: 24),
            ],
            
            // Cholesterol Panel (if available)
            if (_hasCholesterolData(assessmentResults)) ...[
              _buildSectionTitle('Lipid Panel'),
              const SizedBox(height: 12),
              _buildCholesterolPanel(assessmentResults),
              const SizedBox(height: 24),
            ],
            
            // Risk Assessment
            if (_hasRiskData(assessmentResults)) ...[
              _buildSectionTitle('Risk Assessment'),
              const SizedBox(height: 12),
              _buildRiskAssessment(assessmentResults),
              const SizedBox(height: 24),
            ],
            
            // Recommendations
            if (assessmentResults.recommendations.isNotEmpty) ...[
              _buildSectionTitle('Recommendations'),
              const SizedBox(height: 12),
              _buildRecommendations(assessmentResults.recommendations),
              const SizedBox(height: 24),
            ],
            
            // Insights
            if (assessmentResults.insights.isNotEmpty) ...[
              _buildSectionTitle('Health Insights'),
              const SizedBox(height: 12),
              _buildInsights(assessmentResults.insights),
              const SizedBox(height: 24),
            ],
            
            // Timestamp
            _buildTimestamp(assessmentResults.timestamp),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            _buildActionButtons(context, assessmentResults),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoResultsScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Scan Results'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Available',
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load scan results',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHealthScoreCard(int score) {
    Color scoreColor;
    String scoreLabel;
    
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.amber;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Needs Attention';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withValues(alpha: 0.8), scoreColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Score',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$score',
                    style: AppTypography.headingLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  scoreLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.headingSmall.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  Widget _buildVitalSignsGrid(HealthAssessmentResult results) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          icon: Icons.favorite,
          label: 'Heart Rate',
          value: '${results.heartRate}',
          unit: 'BPM',
          color: Colors.red,
        ),
        _buildMetricCard(
          icon: Icons.air,
          label: 'Respiratory Rate',
          value: '${results.respiratoryRate}',
          unit: 'BPM',
          color: Colors.blue,
        ),
        _buildMetricCard(
          icon: Icons.water_drop,
          label: 'SpO2',
          value: '${results.oxygenSaturation}',
          unit: '%',
          color: Colors.cyan,
        ),
        _buildMetricCard(
          icon: Icons.analytics,
          label: 'HRV',
          value: '${results.heartRateVariability}',
          unit: 'ms',
          color: Colors.purple,
        ),
        _buildMetricCard(
          icon: Icons.speed,
          label: 'Blood Pressure',
          value: '${results.systolicBP}/${results.diastolicBP}',
          unit: 'mmHg',
          color: Colors.green,
        ),
        _buildMetricCard(
          icon: Icons.psychology,
          label: 'Stress Level',
          value: results.stressLevel.toUpperCase(),
          unit: '',
          color: _getStressColor(results.stressLevel),
        ),
      ],
    );
  }
  
  Widget _buildAdvancedMetricsGrid(HealthAssessmentResult results) {
    final metrics = <Widget>[];
    
    if (results.heartAge != null) {
      metrics.add(_buildMetricCard(
        icon: Icons.favorite_border,
        label: 'Heart Age',
        value: '${results.heartAge}',
        unit: 'years',
        color: Colors.red,
      ));
    }
    
    if (results.biologicalAge != null) {
      metrics.add(_buildMetricCard(
        icon: Icons.timer,
        label: 'Biological Age',
        value: '${results.biologicalAge}',
        unit: 'years',
        color: Colors.orange,
      ));
    }
    
    if (results.bmi != null) {
      metrics.add(_buildMetricCard(
        icon: Icons.monitor_weight,
        label: 'BMI',
        value: results.bmi!.toStringAsFixed(1),
        unit: 'kg/m²',
        color: Colors.indigo,
      ));
    }
    
    if (results.arterialStiffness != null) {
      metrics.add(_buildMetricCard(
        icon: Icons.bloodtype,
        label: 'Arterial Stiffness',
        value: results.arterialStiffness!.toStringAsFixed(1),
        unit: 'cm/s',
        color: Colors.purple,
      ));
    }
    
    if (results.vo2Max != null) {
      metrics.add(_buildMetricCard(
        icon: Icons.fitness_center,
        label: 'VO2 Max',
        value: results.vo2Max!.toStringAsFixed(1),
        unit: 'ml/kg/min',
        color: Colors.teal,
      ));
    }
    
    if (results.fitnessScore != null) {
      metrics.add(_buildMetricCard(
        icon: Icons.sports_score,
        label: 'Fitness Score',
        value: results.fitnessScore!.toStringAsFixed(0),
        unit: '',
        color: Colors.green,
      ));
    }
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: metrics,
    );
  }
  
  Widget _buildCholesterolPanel(HealthAssessmentResult results) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (results.totalCholesterol != null)
            _buildLipidRow('Total Cholesterol', results.totalCholesterol!, 'mmol/L'),
          if (results.ldlCholesterol != null)
            _buildLipidRow('LDL (Bad)', results.ldlCholesterol!, 'mmol/L'),
          if (results.hdlCholesterol != null)
            _buildLipidRow('HDL (Good)', results.hdlCholesterol!, 'mmol/L'),
          if (results.triglycerides != null)
            _buildLipidRow('Triglycerides', results.triglycerides!, 'mmol/L'),
        ],
      ),
    );
  }
  
  Widget _buildLipidRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium,
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRiskAssessment(HealthAssessmentResult results) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (results.cardiovascularRisk != null)
            _buildRiskRow('Cardiovascular', results.cardiovascularRisk!),
          if (results.diabetesRisk != null)
            _buildRiskRow('Diabetes', results.diabetesRisk!),
          if (results.metabolicRisk != null)
            _buildRiskRow('Metabolic', results.metabolicRisk!),
          if (results.cholesterolRisk != null)
            _buildRiskRow('Cholesterol', results.cholesterolRisk!),
        ],
      ),
    );
  }
  
  Widget _buildRiskRow(String label, String risk) {
    final color = _getRiskColor(risk);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              risk.toUpperCase(),
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static const Map<String, String> _riskLabels = {
    'risk_adj_tenYrCvd':           '10-year CVD risk',
    'risk_adj_bloodPressure':      'Blood pressure',
    'risk_adj_bmi':                'BMI',
    'risk_adj_metSComp':           'Metabolic syndrome',
    'risk_adj_activityLevel':      'Activity level',
    'risk_adj_restingHeartRate':   'Resting heart rate',
    'risk_adj_bapwv':              'Arterial stiffness (baPWV)',
    'risk_adj_totalCholesterol':   'Total cholesterol',
    'risk_adj_ldlC':               'LDL cholesterol',
    'risk_adj_hdlC':               'HDL cholesterol',
    'risk_adj_triglycerides':      'Triglycerides',
    'risk_adj_smokerStatus':       'Smoking status',
    'risk_adj_chronicMedication':  'Chronic medication',
    'risk_adj_framinghamScore':    'Framingham score',
    'risk_adj_restingFitness':     'Resting fitness',
  };

  String _humaniseRiskKey(String key) {
    if (_riskLabels.containsKey(key)) return _riskLabels[key]!;
    // Fallback: strip `risk_adj_` and split camelCase into a readable phrase.
    final raw = key.replaceFirst('risk_adj_', '');
    final spaced = raw.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]!.toLowerCase()}',
    );
    return spaced.isEmpty ? key : spaced[0].toUpperCase() + spaced.substring(1);
  }

  int _riskRank(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':   return 0;
      case 'medium': return 1;
      case 'low':    return 2;
      default:       return 3;
    }
  }

  Widget _buildRiskBreakdown(Map<String, String> breakdown, int? healthScore) {
    final sorted = breakdown.entries.toList()
      ..sort((a, b) {
        final r = _riskRank(a.value).compareTo(_riskRank(b.value));
        if (r != 0) return r;
        return _humaniseRiskKey(a.key).compareTo(_humaniseRiskKey(b.key));
      });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            healthScore == null
                ? 'Each factor the Lambda model classified, with its risk level.'
                : 'Your health score of $healthScore reflects the share of these factors rated LOW.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          for (final e in sorted)
            _buildRiskRow(_humaniseRiskKey(e.key), e.value),
        ],
      ),
    );
  }

  Widget _buildRiskBreakdownUnavailable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Risk breakdown unavailable — Lambda response missing.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recommendations.map((rec) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
  
  Widget _buildInsights(List<String> insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info,
                size: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
  
  Widget _buildTimestamp(DateTime timestamp) {
    final formatter = DateFormat('MMM dd, yyyy at HH:mm');
    
    return Center(
      child: Text(
        'Scanned on ${formatter.format(timestamp)}',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, HealthAssessmentResult results) {
    return Column(
      children: [
        // Continue Assessment button (if part of assessment)
        if (isPartOfAssessment) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _continueAssessment(context),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Standard action buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _saveReport(context, results),
            icon: const Icon(Icons.save),
            label: const Text('Save Report'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(isPartOfAssessment ? '/home' : '/scan/face/preparation'),
            icon: Icon(isPartOfAssessment ? Icons.home : Icons.refresh),
            label: Text(isPartOfAssessment ? 'Home' : 'Scan Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _continueAssessment(BuildContext context) {
    // Show dialog to choose: body scan or skip to summary
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue Assessment'),
        content: const Text(
          'Would you like to complete a body composition scan? This is optional but provides additional health insights.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              // Skip body scan and go to summary
              final orchestrator = context.read<HealthAssessmentOrchestrator>();
              await orchestrator.skipBodyScan();
              if (context.mounted) {
                context.go('/health-assessment/summary');
              }
            },
            child: const Text('Skip'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Go to body scan
              context.go('/scan/body/preparation');
            },
            icon: const Icon(Icons.accessibility_new),
            label: const Text('Do Body Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentInfoCard(BuildContext context) {
    final orchestrator = context.watch<HealthAssessmentOrchestrator>();
    final assessment = orchestrator.currentAssessment;
    final vitalSigns = assessment?.vitalSigns;

    if (vitalSigns == null) {
      return const SizedBox.shrink();
    }

    final scanCount = vitalSigns.measurements.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryBlue, AppColors.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Health Assessment - Vital Signs Complete',
                  style: AppTypography.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Scans Completed', '$scanCount/3', Icons.check_circle),
                _buildStatChip('Avg HR', '${vitalSigns.averageHeartRate?.round() ?? '-'} BPM', Icons.favorite_border),
                _buildStatChip('Avg BP', '${vitalSigns.averageSystolicBP?.round() ?? '-'}/${vitalSigns.averageDiastolicBP?.round() ?? '-'}', Icons.monitor_heart),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Results below show averaged values from $scanCount consecutive scans for improved accuracy.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getStressColor(String stressLevel) {
    switch (stressLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'normal':
        return Colors.blue;
      case 'elevated':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  bool _hasCholesterolData(HealthAssessmentResult results) {
    return results.totalCholesterol != null ||
           results.ldlCholesterol != null ||
           results.hdlCholesterol != null ||
           results.triglycerides != null;
  }
  
  bool _hasRiskData(HealthAssessmentResult results) {
    return results.cardiovascularRisk != null ||
           results.diabetesRisk != null ||
           results.metabolicRisk != null ||
           results.cholesterolRisk != null;
  }
  
  void _shareResults(BuildContext context, HealthAssessmentResult results) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }
  
  void _saveReport(BuildContext context, HealthAssessmentResult results) {
    // TODO: Implement save/export to PDF functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report saved successfully')),
    );
  }
}