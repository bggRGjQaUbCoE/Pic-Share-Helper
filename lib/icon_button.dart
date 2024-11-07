import 'package:flutter/material.dart';

Widget iconButton({
  required BuildContext context,
  required String tooltip,
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: 36,
    height: 36,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
    ),
  );
}
