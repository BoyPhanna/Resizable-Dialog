import 'package:flutter/material.dart';

class ResizableDialogThemeOptions {
  final Color? headerBackgroundColor;
  final Color? handleColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final IconData closeIcon;
  final Color closeIconColor;

  const ResizableDialogThemeOptions({
    this.backgroundColor,
    this.handleColor,
    this.borderColor,
    this.headerBackgroundColor,
    this.textColor,
    this.closeIcon = Icons.close,
    this.closeIconColor = Colors.red,
  });
}
