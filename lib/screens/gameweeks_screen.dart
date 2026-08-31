import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/fpl_provider.dart';
import '../models/gameweek.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import 'gameweek_detail_screen.dart';

enum _GwFilter { all, live, finished, upcoming }

class GameweeksScreen extends StatefulWidget {
  const GameweeksScreen({super.key});

  @override
  State<GameweeksScreen> createState() => _GameweeksScreenState();
}

class _GameweeksScreenState extends State<GameweeksScreen> {
  final ScrollController _scrollController = ScrollController();
  _GwFilter _filter = _GwFilter.all;
  bool _didAutoScroll = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.of(context).background,
            appBar: AppBar(
              title: const Text('Gameweeks Hub'),
              backgroundColor: AppColors.of(context).secondary,
            ),
            body: const LoadingListWidget(),
          );
        }

        final nextGw = provider.gameweeks.where((g) => g.isNext).firstOrNull ??
            provider.gameweeks.where((g) => g.isCurrent).firstOrNull;

        List<Gameweek> filtered = provider.gameweeks;
        if (_filter == _GwFilter.live) {
          filtered = filtered.where((g) => g.isCurrent).toList();
        } else if (_filter == _GwFilter.finished) {
          filtered = filtered.where((g) => g.finished).toList();
        } else if (_filter == _GwFilter.upcoming) {
          filtered = filtered.where((g) => !g.finished && !g.isCurrent).toList();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _didAutoScroll || provider.gameweeks.isEmpty) return;
          final targetGw = provider.currentGameweek?.id ?? 1;
          final targetIndex = provider.gameweeks.indexWhere((gw) => gw.id == targetGw);
          if (targetIndex >= 0 && _scrollController.hasClients) {
            _scrollController.jumpTo(
              (targetIndex * 150.0).clamp(
                0.0,
                _scrollController.position.maxScrollExtent,
              ),
            );
          }
          _didAutoScroll = true;
        });

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Gameweeks Hub'),
            backgroundColor: AppColors.of(context).secondary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => provider.refresh(),
                tooltip: 'Refresh Gameweeks',
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.of(context).primary,
            backgroundColor: AppColors.of(context).cardDark,
            onRefresh: provider.refresh,
            child: Column(
              children: [
                // Next Gameweek Countdown Banner
                if (nextGw != null && nextGw.deadlineTime.isNotEmpty)
                  _buildDeadlineBanner(context, nextGw),
                // Filter Chips Row
                _buildFilterRow(context),
                // Gameweeks List
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final gw = filtered[i];
                      return _buildGameweekCard(context, gw, provider)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: (i % 10) * 30));
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Deadline Banner ────────────────────────────────────────────────────────

  Widget _buildDeadlineBanner(BuildContext context, Gameweek nextGw) {
    DateTime? deadline;
    try {
      deadline = DateTime.parse(nextGw.deadlineTime);
    } catch (_) {}

    String timeRemaining = '';
    if (deadline != null) {
      final now = DateTime.now().toUtc();
      final diff = deadline.toUtc().difference(now);
      if (diff.isNegative) {
        timeRemaining = 'Deadline passed';
      } else if (diff.inDays > 0) {
        timeRemaining = '${diff.inDays}d ${diff.inHours % 24}h remaining';
      } else if (diff.inHours > 0) {
        timeRemaining = '${diff.inHours}h ${diff.inMinutes % 60}m remaining';
      } else {
        timeRemaining = '${diff.inMinutes}m remaining';
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF160D36),
                  Color(0xFF0D0820),
                ]
              : [
                  AppColors.of(context).primary.withAlpha(16),
                  AppColors.of(context).cardDark,
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.of(context).primary.withAlpha(isDark ? 80 : 120),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.of(context).primary.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.timer_outlined,
              color: AppColors.of(context).primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${nextGw.name} Deadline',
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  formatDateTime(nextGw.deadlineTime),
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.of(context).primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.of(context).primary.withAlpha(90)),
            ),
            child: Text(
              timeRemaining,
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters Row ────────────────────────────────────────────────────────────

  Widget _buildFilterRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('All', _GwFilter.all),
          const SizedBox(width: 8),
          _filterChip('Live', _GwFilter.live, const Color(0xFF00FF87)),
          const SizedBox(width: 8),
          _filterChip('Finished', _GwFilter.finished, const Color(0xFF60A5FA)),
          const SizedBox(width: 8),
          _filterChip('Upcoming', _GwFilter.upcoming, const Color(0xFFFBBF24)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _GwFilter filter, [Color? color]) {
    final isSelected = _filter == filter;
    final activeColor = color ?? AppColors.of(context).primary;

    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(30) : AppColors.of(context).cardMedium,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.of(context).divider,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.of(context).textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Gameweek Card ──────────────────────────────────────────────────────────

  Widget _buildGameweekCard(BuildContext context, Gameweek gw, FplProvider provider) {
    final isCurrent = gw.isCurrent;
    final isNext = gw.isNext;
    final topPlayer = gw.topElement != null ? provider.getPlayerById(gw.topElement!) : null;
    final mostCaptainedPlayer = gw.mostCaptained != null ? provider.getPlayerById(gw.mostCaptained!) : null;

    final avgScore = gw.averageEntryScore ?? 0;
    final highScore = gw.highestScore ?? 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppColors.of(context).primary
              : (isNext ? AppColors.of(context).accent : AppColors.of(context).divider),
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.of(context).primary.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameweekDetailScreen(gw: gw, provider: provider),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: isCurrent
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.of(context).primary.withAlpha(20),
                        AppColors.of(context).cardDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  )
                : AppTheme.gradientCard(context: context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: GW Name, Status Badge, Deadline
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          gw.name,
                          style: TextStyle(
                            color: isCurrent ? AppColors.of(context).primary : AppColors.of(context).textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusBadge(context, gw),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          formatDateShort(gw.deadlineTime),
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppColors.of(context).textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),

                // Stats Section (if finished or live)
                if (gw.finished || gw.isCurrent) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppColors.of(context).divider),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricCol('Average', '$avgScore pts', AppColors.of(context).textPrimary),
                      _metricCol('Highest', '$highScore pts', const Color(0xFFFBBF24)),
                      _metricCol('Transfers', _formatCount(gw.transfersMade), const Color(0xFF60A5FA)),
                    ],
                  ),
                ],

                // Top Performer & Most Captained
                if (topPlayer != null || mostCaptainedPlayer != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (topPlayer != null)
                        Expanded(
                          child: _playerMiniBadge(
                            'Top Scorer',
                            topPlayer.webName,
                            '${topPlayer.eventPoints} pts',
                            topPlayer.photoUrl,
                            const Color(0xFF00FF87),
                          ),
                        ),
                      if (topPlayer != null && mostCaptainedPlayer != null)
                        const SizedBox(width: 8),
                      if (mostCaptainedPlayer != null)
                        Expanded(
                          child: _playerMiniBadge(
                            'Most Captained',
                            mostCaptainedPlayer.webName,
                            'C',
                            mostCaptainedPlayer.photoUrl,
                            const Color(0xFFFBBF24),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, Gameweek gw) {
    Color color;
    String label;
    if (gw.isCurrent) {
      color = AppColors.of(context).primary;
      label = 'LIVE';
    } else if (gw.isNext) {
      color = AppColors.of(context).accent;
      label = 'NEXT';
    } else if (gw.finished) {
      color = AppColors.of(context).textSecondary;
      label = 'FINAL';
    } else {
      color = const Color(0xFFFBBF24);
      label = 'UPCOMING';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _metricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _playerMiniBadge(
    String label,
    String name,
    String tag,
    String photoUrl,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppColors.of(context).cardDark,
            ),
            clipBehavior: Clip.antiAlias,
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Icon(Icons.person, size: 14, color: color),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
