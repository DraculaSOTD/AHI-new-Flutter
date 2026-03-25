//
//  AHI Download Assets Page
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../ahi_turnkey_bridge/tk_multiscan_bridge.dart';

class TkDownloadAssetsPage extends StatefulWidget {
  const TkDownloadAssetsPage({
    super.key,
    required this.onContinueTapped,
  });

  final VoidCallback onContinueTapped;

  @override
  State<TkDownloadAssetsPage> createState() => _TkDownloadAssetsPageState();
}

class _TkDownloadAssetsPageState extends State<TkDownloadAssetsPage> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = 'Ready to download scanning resources';
  List<int> _downloadSizes = [];

  @override
  void initState() {
    super.initState();
    _checkDownloadSize();
  }

  void _checkDownloadSize() async {
    try {
      final sizes = await TkMultiScanBridge.instance.checkAHIResourcesDownloadSize();
      setState(() {
        _downloadSizes = sizes;
        final totalMB = sizes.isEmpty ? 0 : (sizes[0] / 1024 / 1024).round();
        _statusMessage = 'Download size: ${totalMB}MB scanning resources';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to check download size';
      });
    }
  }

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusMessage = 'Downloading scanning resources...';
    });

    try {
      // Simulate download progress
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _downloadProgress = i / 100.0;
            _statusMessage = 'Downloading scanning resources... ${i}%';
          });
        }
      }

      // Actually download resources
      final success = await TkMultiScanBridge.instance.downloadAHIResources();
      
      if (success) {
        setState(() {
          _statusMessage = 'Download completed successfully!';
        });
        
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          widget.onContinueTapped();
        }
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Download failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        title: const Text(
          'Download Resources',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Download icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                _isDownloading ? Icons.downloading : Icons.download,
                size: 60,
                color: AppColors.primaryPurple,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              'Scanning Resources Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            const Text(
              'To perform accurate body measurements, we need to download the scanning models and resources.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Status message
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Progress bar
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryPurple,
                ),
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_downloadProgress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Download button
            if (!_isDownloading)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Download Resources',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Notes
            Text(
              '• Download only needs to happen once\n• Resources will be cached for future use\n• Requires internet connection',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}