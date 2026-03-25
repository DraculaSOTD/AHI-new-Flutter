//
//  AHI Expandable Measurement Widget
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/ahi_user_data.dart';
import 'ahi_wheels_measurement_weight.dart';
import 'ahi_wheels_measurement_height.dart';
import '../ahi_text_field_widget.dart';

enum TkMeasurementType {
  weight,
  height,
}

/// Create a widget for the measurement.
///
/// @param measurementType will determine if it needs to be for weight or height.
class TkMeasurementExpandable extends StatefulWidget {
  const TkMeasurementExpandable({
    super.key,
    required this.model,
    this.errorHint,
    this.isValid = true,
    required this.measurementType,
    this.inputLabel,
    this.hint,
  });
  
  final TkUserDataMutable model;
  final String? errorHint, inputLabel, hint;
  final bool isValid;
  final TkMeasurementType measurementType;

  @override
  _TkMeasurementExpandable createState() => _TkMeasurementExpandable();
}

class _TkMeasurementExpandable extends State<TkMeasurementExpandable> {
  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    controller.text = _displayedValue();
    const ExpandableThemeData theme = ExpandableThemeData(hasIcon: false);
    final ExpandableController expandableController =
        ExpandableController(initialExpanded: false);

    return ExpandablePanel(
      theme: theme,
      controller: expandableController,
      header: TkTextField(
        label: (widget.inputLabel == null)
            ? ((widget.measurementType == TkMeasurementType.weight)
                ? 'Weight'
                : 'Height')
            : widget.inputLabel!,
        hint: widget.hint,
        controller: controller,
        suffixText: _displayedSuffix(),
        focusNode: TkAlwaysDisabledFocusNode(),
        errorHint: widget.errorHint,
        isValid: widget.model.isValidData(),
        onTap: () => <void>{
          expandableController.toggle(),
        },
      ),
      collapsed: const SizedBox(height: 0),
      expanded: (widget.measurementType == TkMeasurementType.weight)
          ? TkWeightWheels(
              model: widget.model,
              displayTitle: false,
              height: 150,
              onChange: () {
                controller.text = _displayedValue();
                setState(() {});
              },
            )
          : TkHeightWheels(
              model: widget.model,
              displayTitle: false,
              height: 120,
            ),
    );
  }

  String _displayedValue() {
    if (widget.measurementType == TkMeasurementType.weight) {
      final double? weight = widget.model.weightInKg;
      if (weight != null) {
        if (weight.round() == weight) {
          return weight.round().toString();
        } else {
          return weight.toStringAsFixed(1);
        }
      }
    } else {
      final double? height = widget.model.heightInCm;
      if (height != null) {
        return height.round().toString();
      }
    }
    return '';
  }

  String _displayedSuffix() {
    if (widget.measurementType == TkMeasurementType.weight) {
      return 'kg';
    } else {
      return 'cm';
    }
  }
}