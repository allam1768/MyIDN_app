import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model item agenda rekomendasi harian untuk carousel Daily Briefing
class DailyAgendaItem {
  final String? badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? svgAsset;
  final String buttonText;
  final String? secondaryNotice;
  final double? remainingRatio;
  final List<Color> gradientColors;
  final Color buttonTextColor;
  final Future<void> Function(BuildContext context, WidgetRef ref) onAction;

  const DailyAgendaItem({
    this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.svgAsset,
    required this.buttonText,
    required this.secondaryNotice,
    required this.gradientColors,
    required this.buttonTextColor,
    this.remainingRatio,
    required this.onAction,
  });
}
