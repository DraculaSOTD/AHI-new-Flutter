//
//  AHI Input Sheet Widget
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'ahi_button_widget.dart';

class TkInputSheet extends StatelessWidget {
  const TkInputSheet({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.inputLabel,
    required this.inputWidget,
    required this.onPressed,
  });
  final String title, message, buttonText, inputLabel;
  final Widget inputWidget;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return TkInputWidget(
        title: title,
        message: message,
        inputField: inputWidget,
        button: TkRoundedButton(
          label: buttonText,
          onPressed: onPressed,
        ));
  }

  void show(BuildContext context) {
    showModalBottomSheet<dynamic>(
      backgroundColor: AppColors.backgroundWhite,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.0),
          topLeft: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return this;
      },
    );
  }
}

class TkInputWidget extends StatelessWidget {
  const TkInputWidget({
    super.key,
    required this.title,
    required this.message,
    required this.inputField,
    required this.button,
  });
  final String title, message;
  final TkRoundedButton button;
  final Widget inputField;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        alignment: Alignment.topRight,
        children: <Widget>[
          IconButton(
            padding: const EdgeInsets.all(20.0),
            icon: const Icon(Icons.close, size: 30),
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 54),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  inputField,
                  const SizedBox(height: 20),
                  button,
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}