//
//  AHI Weight Measurement Wheels Widget
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/ahi_user_data.dart';

class TkWeightWheels extends StatefulWidget {
  const TkWeightWheels({
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
  State<TkWeightWheels> createState() => _TkWeightWheelsState();
}

class _TkWeightWheelsState extends State<TkWeightWheels> {
  late FixedExtentScrollController _kgController;
  late FixedExtentScrollController _decimalController;

  @override
  void initState() {
    super.initState();
    
    final double currentWeight = widget.model.weightInKg ?? 70.0;
    final int kg = currentWeight.floor();
    final int decimal = ((currentWeight - kg) * 10).round();
    
    _kgController = FixedExtentScrollController(initialItem: kg - 30);
    _decimalController = FixedExtentScrollController(initialItem: decimal);
  }

  @override
  void dispose() {
    _kgController.dispose();
    _decimalController.dispose();
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
              'Select Weight',
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
              children: [
                // Kg selector
                Expanded(
                  flex: 2,
                  child: CupertinoPicker(
                    scrollController: _kgController,
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      final int kg = index + 30;
                      final double decimal = ((widget.model.weightInKg ?? 70.0) % 1);
                      widget.model.weightInKg = kg + decimal;
                      widget.onChange?.call();
                    },
                    children: List.generate(120, (index) {
                      final int kg = index + 30;
                      return Center(
                        child: Text(
                          kg.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Decimal point
                const Text(
                  '.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                // Decimal selector
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _decimalController,
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      final double kg = (widget.model.weightInKg ?? 70.0).floorToDouble();
                      widget.model.weightInKg = kg + (index / 10.0);
                      widget.onChange?.call();
                    },
                    children: List.generate(10, (index) {
                      return Center(
                        child: Text(
                          index.toString(),
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
                    'kg',
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