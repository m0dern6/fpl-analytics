import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/fpl_provider.dart';
import '../utils/constants.dart';
import '../widgets/pitch_view.dart';
import '../models/player.dart';
import '../utils/formatters.dart';

class FplPitchScreen extends StatelessWidget {
  final Map<String, dynamic> picks;
  final int gwNumber;

  const FplPitchScreen({
    super.key,
    required this.picks,
    required this.gwNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final activeChip = picks['active_chip'] as String?;
        final rawPicksList = (picks['picks'] as List?)
                ?.map((p) => p as Map<String, dynamic>)
                .toList() ??
            [];

        // Calculate synchronized live total points dynamically from live API data
        final totalLivePoints = provider.calculateLiveTeamPoints(
          rawPicksList,
          gw: gwNumber,
          activeChip: activeChip,
        );

        // Find captain and vice-captain for summary
        Map<String, dynamic>? captainPick;
        for (final p in rawPicksList) {
          if (p['is_captain'] == true) {
            captainPick = p;
            break;
          }
        }
        final captainPlayer = captainPick != null
            ? provider.getPlayerById(captainPick['element'] as int)
            : null;

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: Text('Gameweek $gwNumber Pitch'),
            backgroundColor: AppColors.of(context).secondary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => provider.loadLiveGwData(gwNumber),
                tooltip: 'Refresh live points',
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: () => provider.loadLiveGwData(gwNumber),
                color: AppColors.of(context).primary,
                backgroundColor: AppColors.of(context).cardDark,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Real-time Synchronized Total Points Header
                        _buildTotalPointsContainer(
                          context,
                          totalLivePoints,
                          activeChip,
                          captainPlayer,
                          captainPick?['multiplier'] as int? ?? 2,
                        ),
                        const SizedBox(height: 16),
                        // Pitch View
                        PitchView(
                          picks: rawPicksList,
                          provider: provider,
                          gwId: gwNumber,
                          activeChip: activeChip,
                          onPlayerTap: (pick) => _showPlayerPointsSheet(
                            context,
                            pick,
                            provider,
                            activeChip,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTotalPointsContainer(
    BuildContext context,
    int points,
    String? activeChip,
    Player? captainPlayer,
    int captainMultiplier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.of(context).primary.withAlpha(25),
            AppColors.of(context).cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.of(context).primary.withAlpha(90),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).primary.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Live Points Pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.of(context).primary.withAlpha(120),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$points',
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GW$gwNumber PTS',
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.of(context).primary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'LIVE SCORE',
                        style: TextStyle(
                          color: AppColors.of(context).primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Auto-synced from live API',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Active Chip & Captain Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activeChip != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatChipName(activeChip),
                    style: const TextStyle(
                      color: Color(0xFF0C0720),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (captainPlayer != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'C (${captainMultiplier}x)',
                        style: const TextStyle(
                          color: Color(0xFF0C0720),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      captainPlayer.webName,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatChipName(String chip) {
    switch (chip.toLowerCase()) {
      case 'bboost':
        return 'BENCH BOOST';
      case '3xc':
        return 'TRIPLE CAPTAIN';
      case 'freehit':
        return 'FREE HIT';
      case 'wildcard':
        return 'WILDCARD';
      case 'manager':
        return 'ASSISTANT MANAGER';
      default:
        return chip.toUpperCase();
    }
  }

  void _showPlayerPointsSheet(
    BuildContext context,
    Map<String, dynamic> pick,
    FplProvider provider,
    String? activeChip,
  ) {
    final playerId = pick['element'] as int;
    final isCaptain = pick['is_captain'] as bool? ?? false;
    final isViceCaptain = pick['is_vice_captain'] as bool? ?? false;
    final multiplier = pick['multiplier'] as int? ?? 1;
    final isBench = (pick['position'] as int) > 11;

    final player = provider.getPlayerById(playerId);
    final live = provider.getLiveStatsForPlayer(playerId, gw: gwNumber);
    final rawPts = live?['total_points'] as int? ??
        provider.getPlayerPointsForGameweek(playerId, gwNumber);

    int effectivePts = rawPts;
    if (!isBench) {
      effectivePts = rawPts * multiplier;
    } else if (activeChip == 'bboost') {
      effectivePts = rawPts;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlayerPointsSheet(
        player: player,
        live: live,
        effectivePts: effectivePts,
        isCaptain: isCaptain,
        isViceCaptain: isViceCaptain,
        multiplier: multiplier,
        isBench: isBench,
        provider: provider,
        gwNumber: gwNumber,
      ),
    );
  }
}

class _PlayerPointsSheet extends StatelessWidget {
  final Player? player;
  final Map<String, dynamic>? live;
  final int effectivePts;
  final bool isCaptain;
  final bool isViceCaptain;
  final int multiplier;
  final bool isBench;
  final FplProvider provider;
  final int gwNumber;

  const _PlayerPointsSheet({
    required this.player,
    required this.live,
    required this.effectivePts,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.multiplier,
    required this.isBench,
    required this.provider,
    required this.gwNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (player == null) return const SizedBox.shrink();

    final team = provider.getTeamById(player!.teamId);
    final posColor = getPositionColor(player!.elementType);
    final rawPts = live?['total_points'] as int? ??
        provider.getPlayerPointsForGameweek(player!.id, gwNumber);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.of(context).cardMedium,
                  border: Border.all(color: posColor.withAlpha(90)),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: player!.photoUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorWidget: (_, _, _) => const Icon(Icons.person),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player!.webName,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          team?.name ?? '',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _badge(getPositionShort(player!.elementType), posColor),
                        if (isCaptain) ...[
                          const SizedBox(width: 6),
                          _badge('C (${multiplier}x)', const Color(0xFFFBBF24)),
                        ],
                        if (isViceCaptain) ...[
                          const SizedBox(width: 6),
                          _badge('VC', const Color(0xFF60A5FA)),
                        ],
                        if (isBench) ...[
                          const SizedBox(width: 6),
                          _badge('BENCH', AppColors.of(context).textSecondary),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Points Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.of(context).primary.withAlpha(90),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$effectivePts',
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      multiplier > 1 ? '$rawPts × $multiplier' : 'PTS',
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.of(context).divider, height: 1),
          const SizedBox(height: 16),
          if (live != null)
            _buildStatsGrid(context, live!)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No live match events recorded yet',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    final items = <_StatItem>[];
    if ((stats['minutes'] ?? 0) > 0) {
      items.add(_StatItem('Minutes Played', '${stats['minutes']}\''));
    }
    if ((stats['goals_scored'] ?? 0) > 0) {
      items.add(_StatItem('Goals Scored', '${stats['goals_scored']}'));
    }
    if ((stats['assists'] ?? 0) > 0) {
      items.add(_StatItem('Assists', '${stats['assists']}'));
    }
    if ((stats['clean_sheets'] ?? 0) > 0) {
      items.add(_StatItem('Clean Sheet', '1'));
    }
    if ((stats['saves'] ?? 0) > 0) {
      items.add(_StatItem('Saves', '${stats['saves']}'));
    }
    if ((stats['bonus'] ?? 0) > 0) {
      items.add(_StatItem('Bonus Points', '+${stats['bonus']}'));
    }
    if ((stats['bps'] ?? 0) > 0) {
      items.add(_StatItem('BPS Score', '${stats['bps']}'));
    }
    if ((stats['yellow_cards'] ?? 0) > 0) {
      items.add(_StatItem('Yellow Card', '1'));
    }
    if ((stats['red_cards'] ?? 0) > 0) {
      items.add(_StatItem('Red Card', '1'));
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Played 0 mins / Yet to play in GW$gwNumber',
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardMedium,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.of(context).divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              items[i].label,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              items[i].value,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  _StatItem(this.label, this.value);
}
