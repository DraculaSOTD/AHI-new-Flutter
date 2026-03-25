//
//  AHI Context Extensions
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';

extension ContextAHI on BuildContext {
  /// Show processing indicator (placeholder implementation)
  void showProcessing() {
    // TODO: Implement processing indicator overlay
    // This would typically show a full-screen loading overlay
  }

  /// Hide processing indicator (placeholder implementation)
  void hideProcessing() {
    // TODO: Implement processing indicator removal
    // This would typically hide the full-screen loading overlay
  }

  /// Show error popup
  void showErrorPopup(Object? error) {
    showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('An error occurred: ${error.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Check if the context is still mounted
  bool get mounted => this.mounted;
}