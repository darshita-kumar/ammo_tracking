import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'dart:io';

Future<void> saveExcelToDownloads({
  required BuildContext context,
  required xl.Excel excel,
  required String fileName,
}) async {
  try {
    final bytes = excel.encode()!;
    final sanitizedName = fileName.replaceAll(' ', '_');
    final file = File('/storage/emulated/0/Download/$sanitizedName');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Downloads: $sanitizedName'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }
}