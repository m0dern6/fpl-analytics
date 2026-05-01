import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final Color? valueColor;
  final String? imageUrl;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.gradientColors,
    this.onTap,
    this.valueColor,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = valueColor ?? AppColors.of(context).primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.of(context).divider, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Content on the left
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  14,
                  imageUrl != null ? 80 : 14,
                  14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(24),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: accentColor, size: 16),
                        ),
                        if (onTap != null && imageUrl == null) ...[
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              color: AppColors.of(context).textSecondary, size: 16),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Player image on the right — touches bottom, margin top + right only
            if (imageUrl != null)
              Positioned(
                top: 8,
                right: 4,
                bottom: 0,
                child: AspectRatio(
                  aspectRatio: 110 / 140,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
