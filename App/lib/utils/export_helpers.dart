import 'dart:convert';
import 'package:flutter/services.dart';

/// Helpers for exporting tabular data to the clipboard.
class ExportHelpers {
  static Future<void> copyJsonToClipboard(List<Map<String, dynamic>> rows) async {
    final encoded = const JsonEncoder.withIndent('  ').convert(rows);
    await Clipboard.setData(ClipboardData(text: encoded));
  }

  static Future<void> copyCsvToClipboard(
    List<Map<String, dynamic>> rows, {
    List<String>? columns,
  }) async {
    if (rows.isEmpty) {
      await Clipboard.setData(const ClipboardData(text: ''));
      return;
    }

    final keys = columns ?? rows.first.keys.toList();
    final buffer = StringBuffer(keys.join(','));
    buffer.writeln();

    for (final row in rows) {
      buffer.writeln(
        keys
            .map((key) => _escapeCsv(row[key]?.toString() ?? ''))
            .join(','),
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
