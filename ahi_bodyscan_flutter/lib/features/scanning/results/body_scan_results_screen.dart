import 'package:flutter/material.dart';
import '../../../services/ahi_scanner/models/scan_results.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/mesh_viewer.dart';

class BodyScanResultsScreen extends StatefulWidget {
  final BodyScanResult result;

  const BodyScanResultsScreen({
    super.key,
    required this.result,
  });

  @override
  State<BodyScanResultsScreen> createState() => _BodyScanResultsScreenState();
}

class _BodyScanResultsScreenState extends State<BodyScanResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Body Scan Results',
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _shareResults(),
            icon: Icon(
              Icons.share,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPurple,
          tabs: const [
            Tab(text: 'Measurements'),
            Tab(text: '3D View'),
            Tab(text: 'Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeasurementsTab(),
          _build3DTab(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    final bottomInset =
        MediaQueryData.fromView(View.of(context)).viewPadding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scan info header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple.withValues(alpha: 0.1),
                  AppColors.secondaryBlue.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.check,
                    color: AppColors.textWhite,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Complete',
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Scanned on ${_formatDate(widget.result.scanDate)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Body measurements
          _buildMeasurementSection(
            'Body Measurements',
            [
              _buildMeasurementItem('Chest', widget.result.chestInCm, 'cm'),
              _buildMeasurementItem('Waist', widget.result.waistInCm, 'cm'),
              _buildMeasurementItem('Hips', widget.result.hipsInCm, 'cm'),
              _buildMeasurementItem('Thigh', widget.result.thighInCm, 'cm'),
              _buildMeasurementItem('Inseam', widget.result.inseamInCm, 'cm'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Body composition
          _buildMeasurementSection(
            'Body Composition',
            [
              _buildMeasurementItem('Body Fat', widget.result.bodyfatInPercent, '%'),
              _buildMeasurementItem('Muscle Mass', widget.result.muscleMassInKg, 'kg'),
              _buildMeasurementItem('Fat Mass', widget.result.fatMassInKg, 'kg'),
              _buildMeasurementItem('Weight Prediction', widget.result.weightPredictInKg, 'kg'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Ratios
          _buildMeasurementSection(
            'Health Ratios',
            [
              _buildMeasurementItem('Waist-to-Height', widget.result.waistToHeightRatio, ''),
              _buildMeasurementItem('Waist-to-Hip', widget.result.waistToHipRatio, ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3DTab() {
    return Column(
      children: [
        if (widget.result.meshPath != null)
          Expanded(
            child: MeshViewer(
              meshPath: widget.result.meshPath!,
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load 3D model: $error')),
                );
              },
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_in_ar,
                    size: 80,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '3D Model Not Available',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '3D mesh generation was not completed for this scan.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        
        // 3D controls info
        Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQueryData.fromView(View.of(context)).viewPadding.bottom),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Text(
                '3D Model Controls',
                style: AppTypography.headingSmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _build3DControlTip(Icons.pan_tool, 'Drag to rotate'),
                  _build3DControlTip(Icons.zoom_in, 'Pinch to zoom'),
                  _build3DControlTip(Icons.center_focus_strong, 'Tap to reset'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisTab() {
    final bottomInset =
        MediaQueryData.fromView(View.of(context)).viewPadding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health insights
          Text(
            'Health Insights',
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: 16),
          
          // Body fat analysis
          if (widget.result.bodyfatInPercent != null)
            _buildInsightCard(
              title: 'Body Fat Analysis',
              value: '${widget.result.bodyfatInPercent!.toStringAsFixed(1)}%',
              description: _getBodyFatAnalysis(widget.result.bodyfatInPercent!),
              color: _getBodyFatColor(widget.result.bodyfatInPercent!),
            ),
          
          const SizedBox(height: 16),
          
          // Waist-to-height ratio
          if (widget.result.waistToHeightRatio != null)
            _buildInsightCard(
              title: 'Waist-to-Height Ratio',
              value: widget.result.waistToHeightRatio!.toStringAsFixed(2),
              description: _getWaistToHeightAnalysis(widget.result.waistToHeightRatio!),
              color: _getWaistToHeightColor(widget.result.waistToHeightRatio!),
            ),
          
          const SizedBox(height: 24),
          
          // Raw data section
          ExpansionTile(
            title: Text(
              'Technical Details',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Information',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDataRow('Biological Sex', widget.result.biologicalSex),
                    _buildDataRow('Height', '${widget.result.heightInCm.toStringAsFixed(1)} cm'),
                    _buildDataRow('Weight', '${widget.result.weightInKg.toStringAsFixed(1)} kg'),
                    _buildDataRow('Age', '${widget.result.ageInYears} years'),
                    const SizedBox(height: 16),
                    Text(
                      'Raw Measurements',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.result.rawChestInCm != null)
                      _buildDataRow('Raw Chest', '${widget.result.rawChestInCm!.toStringAsFixed(1)} cm'),
                    if (widget.result.rawWaistInCm != null)
                      _buildDataRow('Raw Waist', '${widget.result.rawWaistInCm!.toStringAsFixed(1)} cm'),
                    if (widget.result.rawBodyfatPercent != null)
                      _buildDataRow('Raw Body Fat', '${widget.result.rawBodyfatPercent!.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementSection(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: AppTypography.headingSmall,
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMeasurementItem(String label, double? value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DControlTip(IconData icon, String label) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getBodyFatAnalysis(double bodyFat) {
    // These ranges are general guidelines and may vary by age/gender
    if (bodyFat < 6) return 'Essential fat range - very low';
    if (bodyFat < 14) return 'Athletic range - excellent';
    if (bodyFat < 21) return 'Fitness range - good';
    if (bodyFat < 25) return 'Average range - acceptable';
    return 'Above average - consider lifestyle changes';
  }

  Color _getBodyFatColor(double bodyFat) {
    if (bodyFat < 14) return AppColors.success;
    if (bodyFat < 25) return AppColors.warning;
    return AppColors.error;
  }

  String _getWaistToHeightAnalysis(double ratio) {
    if (ratio < 0.4) return 'Very low - excellent health indicator';
    if (ratio < 0.5) return 'Healthy range - low risk';
    if (ratio < 0.6) return 'Moderate risk - consider lifestyle changes';
    return 'High risk - consult healthcare provider';
  }

  Color _getWaistToHeightColor(double ratio) {
    if (ratio < 0.5) return AppColors.success;
    if (ratio < 0.6) return AppColors.warning;
    return AppColors.error;
  }

  void _shareResults() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality coming soon')),
    );
  }
}