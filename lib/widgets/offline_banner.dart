import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// A sticky banner shown when the app is displaying cached data offline.
class OfflineBanner extends StatelessWidget {
  final DateTime? cachedAt;
  final bool isOffline;
  final VoidCallback? onRefresh;

  const OfflineBanner({
    super.key,
    this.cachedAt,
    required this.isOffline,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && cachedAt == null) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final label = cachedAt != null
        ? 'Offline — showing cached data from ${formatDateTime(cachedAt!.toIso8601String())}'
        : 'Offline — no cached data available';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.warning.withAlpha(230),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: colors.secondary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRefresh != null)
              GestureDetector(
                onTap: onRefresh,
                child: Icon(Icons.refresh_rounded, color: colors.secondary, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

/// A widget that wraps a [child] and shows an [OfflineBanner] at the top.
class OfflineAwareScaffold extends StatelessWidget {
  final bool isOffline;
  final DateTime? cachedAt;
  final VoidCallback? onRefresh;
  final Widget child;

  const OfflineAwareScaffold({
    super.key,
    required this.isOffline,
    this.cachedAt,
    this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && cachedAt == null) return child;

    return Column(
      children: [
        OfflineBanner(
          isOffline: isOffline,
          cachedAt: cachedAt,
          onRefresh: onRefresh,
        ),
        Expanded(child: child),
      ],
    );
  }
}
