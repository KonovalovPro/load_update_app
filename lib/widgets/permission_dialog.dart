import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> showPermissionDialog(
  BuildContext context, {
  required Permission permission,
  required String title,
  required String rationale,
}) async {
  return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(
            '$rationale\n\nPermission: ${permission.toString().split('.').last}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        ),
      ).then((value) => value ?? false);
}
