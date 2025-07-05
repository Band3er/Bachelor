library globals;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

var now = DateTime.now();
var time =
    '[${now.hour.toString().padLeft(2, '0')}:'
    '${now.minute.toString().padLeft(2, '0')}:'
    '${now.second.toString().padLeft(2, '0')}]';

void showAppThemedSnackBar(BuildContext context, String message) {
  final theme = Theme.of(context);

  final snackBar = SnackBar(
    content: Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onPrimary,
      ),
    ),
    backgroundColor: theme.colorScheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
