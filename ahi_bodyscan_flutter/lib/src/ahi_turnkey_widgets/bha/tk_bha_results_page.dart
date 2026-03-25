//
//  AHI BHA Results Page - Displays comprehensive health assessment results
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../ahi_turnkey_models/bha/ahi_bha_model.dart';
import '../../../core/theme/app_colors.dart';

class TkBHAResultsPage extends StatefulWidget {
  final BHAProfile bhaProfile;
  final VoidCallback? onClose;
  final VoidCallback? onShareResults;
  final VoidCallback? onViewRecommendations;

  const TkBHAResultsPage({
    super.key,
    required this.bhaProfile,
    this.onClose,
    this.onShareResults,
    this.onViewRecommendations,
  });

  @override
  State<TkBHAResultsPage> createState() => _TkBHAResultsPageState();
}

class _TkBHAResultsPageState extends State<TkBHAResultsPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedCategoryIndex = -1; // -1 means overview

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Health Assessment'),
        leading: widget.onClose != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onClose,
              )
            : null,
        actions: [
          if (widget.onShareResults != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: widget.onShareResults,
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Overall Score Header
        _buildOverallScoreHeader(),
        
        // Category Tabs
        _buildCategoryTabs(),
        
        // Content Area
        Expanded(
          child: _selectedCategoryIndex == -1
              ? _buildOverviewContent()
              : _buildCategoryContent(_selectedCategoryIndex),
        ),
        
        // Action Buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildOverallScoreHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRiskLevelColor(widget.bhaProfile.overallRiskLevel).withValues(alpha: 0.1),
            _getRiskLevelColor(widget.bhaProfile.overallRiskLevel).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getRiskLevelColor(widget.bhaProfile.overallRiskLevel).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Overall Health Score',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          // Animated Score Circle
          _buildAnimatedScoreCircle(),
          
          const SizedBox(height: 16),
          Text(
            widget.bhaProfile.overallRiskLevel.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _getRiskLevelColor(widget.bhaProfile.overallRiskLevel),
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          Text(
            _getOverallDescription(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, duration: 600.ms);
  }

  Widget _buildAnimatedScoreCircle() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
          ),
          
          // Animated Progress Circle
          SizedBox(
            width: 120,
            height: 120,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: widget.bhaProfile.overallScore / 100),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getRiskLevelColor(widget.bhaProfile.overallRiskLevel),
                  ),
                );
              },
            ),
          ),
          
          // Score Text
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: widget.bhaProfile.overallScore),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '${value.round()}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getRiskLevelColor(widget.bhaProfile.overallRiskLevel),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = BHARiskCategory.values;
    
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Overview Tab
            _buildCategoryTab(
              'Overview',
              '📋',
              -1,
              widget.bhaProfile.riskAssessments.length,
            ),
            
            // Category Tabs
            ...categories.map((category) {
              final categoryAssessments = widget.bhaProfile.getRiskAssessmentsByCategory(category);
              if (categoryAssessments.isEmpty) return const SizedBox.shrink();
              
              return _buildCategoryTab(
                category.label,
                category.icon,
                categories.indexOf(category),
                categoryAssessments.length,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String label, String icon, int index, int count) {
    final isSelected = _selectedCategoryIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Level Breakdown
          _buildRiskLevelBreakdown(),
          
          const SizedBox(height: 24),
          
          // Category Scores Chart
          _buildCategoryScoresChart(),
          
          const SizedBox(height: 24),
          
          // Top Recommendations
          _buildTopRecommendations(),
          
          const SizedBox(height: 24),
          
          // Next Assessment Info
          _buildNextAssessmentInfo(),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(int categoryIndex) {
    final category = BHARiskCategory.values[categoryIndex];
    final assessments = widget.bhaProfile.getRiskAssessmentsByCategory(category);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${category.label} Assessment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...assessments.map((assessment) => _buildAssessmentCard(assessment)),
        ],
      ),
    );
  }

  Widget _buildRiskLevelBreakdown() {
    final riskCounts = <BHARiskLevel, int>{};
    for (final level in BHARiskLevel.values) {
      riskCounts[level] = widget.bhaProfile.riskAssessments
          .where((a) => a.riskLevel == level)
          .length;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Level Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ...BHARiskLevel.values.where((level) => level != BHARiskLevel.unknown).map((level) {
              final count = riskCounts[level] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getRiskLevelColor(level),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        level.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRiskLevelColor(level).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: _getRiskLevelColor(level),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildCategoryScoresChart() {
    final categoryScores = widget.bhaProfile.categoryScores;
    if (categoryScores.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Scores',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ...categoryScores.entries.map((entry) {
              final category = entry.key;
              final score = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(category.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.label,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${score.round()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: score / 100),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getScoreColor(score),
                          ),
                          minHeight: 6,
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildTopRecommendations() {
    if (widget.bhaProfile.recommendations.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ...widget.bhaProfile.recommendations.take(3).map((recommendation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            if (widget.bhaProfile.recommendations.length > 3)
              GestureDetector(
                onTap: widget.onViewRecommendations,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Text(
                    'View all ${widget.bhaProfile.recommendations.length} recommendations →',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildNextAssessmentInfo() {
    if (widget.bhaProfile.nextAssessmentDate == null) return const SizedBox.shrink();
    
    final daysUntilNext = widget.bhaProfile.nextAssessmentDate!
        .difference(DateTime.now())
        .inDays;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Assessment',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended in $daysUntilNext days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms);
  }

  Widget _buildAssessmentCard(BHARiskAssessment assessment) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getRiskLevelColor(assessment.riskLevel),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assessment.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRiskLevelColor(assessment.riskLevel).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${assessment.score.round()}',
                    style: TextStyle(
                      color: _getRiskLevelColor(assessment.riskLevel),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRiskLevelColor(assessment.riskLevel).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                assessment.riskLevel.label,
                style: TextStyle(
                  color: _getRiskLevelColor(assessment.riskLevel),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              assessment.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            if (assessment.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recommendations:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...assessment.recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rec,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            if (assessment.metrics.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: assessment.metrics.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.onViewRecommendations != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onViewRecommendations!,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('View All Recommendations'),
              ),
            ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.low:
        return const Color(0xFF4CAF50); // Green
      case BHARiskLevel.moderate:
        return const Color(0xFFFFA726); // Orange
      case BHARiskLevel.high:
        return const Color(0xFFE53935); // Red
      case BHARiskLevel.unknown:
        return const Color(0xFF757575); // Grey
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 75) return const Color(0xFF4CAF50); // Green
    if (score >= 50) return const Color(0xFFFFA726); // Orange
    return const Color(0xFFE53935); // Red
  }

  String _getOverallDescription() {
    switch (widget.bhaProfile.overallRiskLevel) {
      case BHARiskLevel.low:
        return 'Your health assessment shows low risk across most categories. Continue your healthy lifestyle!';
      case BHARiskLevel.moderate:
        return 'Your health assessment shows some areas for improvement. Focus on the recommendations provided.';
      case BHARiskLevel.high:
        return 'Your health assessment indicates several areas needing attention. Please consult healthcare professionals.';
      case BHARiskLevel.unknown:
        return 'Unable to complete comprehensive assessment. Please try again or consult healthcare provider.';
    }
  }
}