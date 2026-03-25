//
//  AHI Height Measurement Wheels Widget
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/ahi_user_data.dart';

class TkHeightWheels extends StatefulWidget {
  const TkHeightWheels({
    super.key,
    required this.model,
    this.displayTitle = true,
    this.height = 200,
    this.onChange,
  });

  final TkUserDataMutable model;
  final bool displayTitle;
  final double height;
  final VoidCallback? onChange;

  @override
  State<TkHeightWheels> createState() => _TkHeightWheelsState();
}

class _TkHeightWheelsState extends State<TkHeightWheels> {
  late FixedExtentScrollController _cmController;

  @override
  void initState() {
    super.initState();
    
    final double currentHeight = widget.model.heightInCm ?? 170.0;
    final int cm = currentHeight.round();
    
    _cmController = FixedExtentScrollController(initialItem: cm - 100);
  }

  @override
  void dispose() {
    _cmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (widget.displayTitle) ...[
            const SizedBox(height: 16),
            const Text(
              'Select Height',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Height selector
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _cmController,
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      final int cm = index + 100;
                      widget.model.heightInCm = cm.toDouble();
                      widget.onChange?.call();
                    },
                    children: List.generate(150, (index) {
                      final int cm = index + 100;
                      return Center(
                        child: Text(
                          cm.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Unit label
                const Padding(
                  padding: EdgeInsets.only(left: 8, right: 16),
                  child: Text(
                    'cm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}