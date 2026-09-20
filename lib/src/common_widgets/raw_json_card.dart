import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Komponen reusable untuk menampilkan respon data mentah (JSON)
/// Dilengkapi fitur expandable, formatting JSON, dan tombol Salin (Copy).
class RawJsonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final dynamic data;
  final bool initiallyExpanded;

  const RawJsonCard({
    super.key,
    required this.title,
    this.icon = Icons.code,
    this.color = Colors.blueGrey,
    required this.data,
    this.initiallyExpanded = false,
  });

  String _formatPrettyJson(dynamic raw) {
    if (raw == null) return 'Data Kosong (null)';
    try {
      dynamic obj = raw;
      if (raw is String) {
        obj = jsonDecode(raw);
      }
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return raw.toString();
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title berhasil disalin ke clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prettyText = _formatPrettyJson(data);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Salin JSON',
              onPressed: () => _copyToClipboard(context, prettyText),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade900,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: SelectableText(
                prettyText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.lightGreenAccent,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
