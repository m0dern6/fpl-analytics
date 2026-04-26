import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

String formatPrice(int rawCost) {
  return '£${(rawCost / 10).toStringAsFixed(1)}m';
}

String formatPercent(String? value) {
  if (value == null) return '0%';
  final d = double.tryParse(value) ?? 0;
  return '${d.toStringAsFixed(1)}%';
}

String formatForm(String? value) {
  if (value == null) return '0.0';
  final d = double.tryParse(value) ?? 0;
  return d.toStringAsFixed(1);
}

String formatDouble(String? value, {int decimals = 1}) {
  if (value == null) return '0.${'0' * decimals}';
  final d = double.tryParse(value) ?? 0;
  return d.toStringAsFixed(decimals);
}

Color getDifficultyColor(int difficulty) {
  return DifficultyConstants.colors[difficulty] ?? Colors.grey;
}

String getDifficultyLabel(int difficulty) {
  return DifficultyConstants.labels[difficulty] ?? 'Unknown';
}

String getPositionShort(int elementType) {
  return PositionConstants.positionNames[elementType] ?? 'UNK';
}

String getPositionFull(int elementType) {
  return PositionConstants.positionFullNames[elementType] ?? 'Unknown';
}

Color getPositionColor(int elementType) {
  return PositionConstants.positionColors[elementType] ?? Colors.grey;
}

String formatDateShort(String? isoDate) {
  if (isoDate == null) return '';
  try {
    final dt = DateTime.parse(isoDate);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  } catch (_) {
    return '';
  }
}

String formatDateTime(String? isoDate) {
  if (isoDate == null) return '';
  try {
    final dt = DateTime.parse(isoDate).toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} $hour:$minute';
  } catch (_) {
    return '';
  }
}

String formatStatusLabel(String? status) {
  switch (status) {
    case 'a':
      return 'Available';
    case 'd':
      return 'Doubtful';
    case 'i':
      return 'Injured';
    case 's':
      return 'Suspended';
    case 'u':
      return 'Unavailable';
    case 'n':
      return 'Not in Squad';
    default:
      return 'Available';
  }
}

Color getStatusColor(String? status) {
  switch (status) {
    case 'a':
      return const Color(0xFF00D68F);
    case 'd':
      return const Color(0xFFFFCC02);
    case 'i':
      return const Color(0xFFFF5C5C);
    case 's':
      return const Color(0xFFFF5C5C);
    case 'u':
      return const Color(0xFFFF5C5C);
    default:
      return const Color(0xFF00D68F);
  }
}

String formatNumber(num value) {
  return NumberFormat('#,###').format(value);
}
