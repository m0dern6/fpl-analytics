import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/fpl_provider.dart';
import '../models/gameweek.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import 'fixtures_screen.dart';

class GameweeksScreen extends StatelessWidget {
  const GameweeksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Gameweeks'),
            backgroundColor: AppColors.secondary,
          ),
          body: _GameweeksList(provider: provider),
        );
      },
    );
  }
}

class _GameweeksList extends StatefulWidget {
  final FplProvider provider;

  const _GameweeksList({required this.provider});

  @override
  State<_GameweeksList> createState() => _GameweeksListState();
}

class _GameweeksListState extends State<_GameweeksList> {
  final ScrollController _scrollController = ScrollController();
  bool _didAutoScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    if (provider.isLoading) {
      return const LoadingListWidget();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAutoScroll || provider.gameweeks.isEmpty) return;
      final targetGw =
          provider.currentGameweek?.id ?? provider.gameweeks.last.id;
      final targetIndex = provider.gameweeks.indexWhere(
        (gw) => gw.id == targetGw,
      );
      if (targetIndex >= 0 && _scrollController.hasClients) {
        _scrollController.jumpTo(
          (targetIndex * 132.0).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
        );
      }
      _didAutoScroll = true;
    });

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      onRefresh: provider.refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.gameweeks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final gw = provider.gameweeks[i];
          return _GameweekCard(
            gw: gw,
            provider: provider,
          ).animate().fadeIn(delay: Duration(milliseconds: i * 30));
        },
      ),
    );
  }
}

class _GameweekCard extends StatelessWidget {
  final Gameweek gw;
  final FplProvider provider;

  const _GameweekCard({required this.gw, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isHighlighted = gw.isCurrent || gw.isNext;
    final topElementPlayer = gw.topElement != null
        ? provider.getPlayerById(gw.topElement!)
        : null;
    final mostTransferredPlayer = gw.mostTransferredIn != null
        ? provider.getPlayerById(gw.mostTransferredIn!)
        : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FixturesScreen(initialGameweek: gw.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: isHighlighted
            ? AppTheme.purpleGradient()
            : AppTheme.gradientCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        gw.name,
                        style: TextStyle(
                          color: isHighlighted
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusBadge(gw),
                    ],
                  ),
                ),
                Text(
                  formatDateShort(gw.deadlineTime),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ],
            ),
            if (gw.finished || gw.isCurrent) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (gw.averageEntryScore != null)
                    _stat('Avg Score', '${gw.averageEntryScore} pts'),
                  if (gw.highestScore != null) ...[
                    const SizedBox(width: 20),
                    _stat('Highest', '${gw.highestScore} pts'),
                  ],
                  if (gw.transfersMade > 0) ...[
                    const SizedBox(width: 20),
                    _stat('Transfers', _formatCount(gw.transfersMade)),
                  ],
                ],
              ),
              if (topElementPlayer != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Top: ${topElementPlayer.webName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              if (mostTransferredPlayer != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Most Transferred: ${mostTransferredPlayer.webName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(Gameweek gw) {
    Color color;
    String label;
    if (gw.isCurrent) {
      color = AppColors.primary;
      label = 'LIVE';
    } else if (gw.isNext) {
      color = AppColors.accent;
      label = 'NEXT';
    } else if (gw.finished) {
      color = AppColors.textSecondary;
      label = 'DONE';
    } else {
      color = AppColors.warning;
      label = 'UPCOMING';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
