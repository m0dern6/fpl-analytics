import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class DifficultyBadge extends StatelessWidget {
  final int difficulty;
  final bool showLabel;
  final double size;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.showLabel = false,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final color = getDifficultyColor(difficulty);
    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(51),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              getDifficultyLabel(difficulty),
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$difficulty',
          style: TextStyle(
            color: difficulty <= 2 ? Colors.black : Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class DifficultyRow extends StatelessWidget {
  final List<int> difficulties;
  final double badgeSize;

  const DifficultyRow({
    super.key,
    required this.difficulties,
    this.badgeSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: difficulties
          .map((d) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: DifficultyBadge(difficulty: d, size: badgeSize),
              ))
          .toList(),
    );
  }
}
