//
//  AHI Text Field Widget
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TkTextField extends StatelessWidget {
  const TkTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.suffixText,
    this.focusNode,
    this.errorHint,
    this.isValid = true,
    this.onTap,
    this.onChanged,
    this.readOnly = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? suffixText;
  final FocusNode? focusNode;
  final String? errorHint;
  final bool isValid;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? AppColors.borderMedium : AppColors.error,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? AppColors.borderMedium : AppColors.error,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? AppColors.primaryPurple : AppColors.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: AppColors.backgroundWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        if (!isValid && errorHint != null) ...[
          const SizedBox(height: 4),
          Text(
            errorHint!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

class TkAlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}