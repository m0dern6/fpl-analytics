import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fpl_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/pitch_view.dart';
import '../models/player.dart';
import '../utils/formatters.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final provider = context.read<FplProvider>();
    final activeChip = picks['active_chip'] as String?;
    final totalPoints = picks['entry_history']?['points'] as int? ?? 0;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text('Gameweek $gwNumber Pitch'),
        backgroundColor: AppColors.of(context).secondary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: () =>
                provider.loadLiveGwData(gwNumber), // Example refresh
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTotalPointsContainer(totalPoints),
                    const SizedBox(height: 32),
                    PitchView(
                      picks: (picks['picks'] as List)
                          .map((p) => p as Map<String, dynamic>)
                          .toList(),
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalPointsContainer(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF34D399).withAlpha(100),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$points',
            style: const TextStyle(
              color: Color(0xFF34D399),
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          Text(
            'GW$gwNumber PTS',
            style: const TextStyle(
              color: Color(0xFF34D399),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
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
    final live = provider.getLiveStatsForPlayer(playerId);
    final rawPts = live?.totalPoints ?? 0;

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
      ),
    );
  }
}

// Reusing _PlayerPointsSheet from fpl_team_screen (I should have moved it too, but for now I'll just copy it)
class _PlayerPointsSheet extends StatelessWidget {
  final Player? player;
  final Map<String, dynamic>? live;
  final int effectivePts;
  final bool isCaptain;
  final bool isViceCaptain;
  final int multiplier;
  final bool isBench;
  final FplProvider provider;

  const _PlayerPointsSheet({
    required this.player,
    required this.live,
    required this.effectivePts,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.multiplier,
    required this.isBench,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final posColor = player != null
        ? getPositionColor(player!.elementType)
        : AppColors.of(context).textSecondary;
    final team = player != null ? provider.getTeamById(player!.teamId) : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.of(context).divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.of(context).cardMedium,
                  border: Border.all(color: posColor.withAlpha(120), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: player != null
                    ? CachedNetworkImage(
                        imageUrl: player!.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Icon(Icons.person, color: posColor, size: 28),
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.person, color: posColor, size: 28),
                      )
                    : Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player?.webName ?? 'Unknown',
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isCaptain) ...[
                          const SizedBox(width: 8),
                          _badge('C', const Color(0xFFFFD700)),
                        ] else if (isViceCaptain) ...[
                          const SizedBox(width: 8),
                          _badge('V', AppColors.of(context).accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: posColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: posColor.withAlpha(120)),
                          ),
                          child: Text(
                            player != null
                                ? getPositionShort(player!.elementType)
                                : '–',
                            style: TextStyle(
                              color: posColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          team?.name ?? '',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (isBench) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(Bench)',
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.of(context).primary.withAlpha(80)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$effectivePts',
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'PTS',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: AppColors.of(context).divider, height: 1),
          const SizedBox(height: 16),
          if (live != null)
            _buildStatsGrid(context, live!)
          else
            Center(
              child: Text(
                'No live data for this player yet',
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    final items = <_StatItem>[];
    if (stats['minutes'] > 0)
      items.add(_StatItem('Minutes', '${stats['minutes']}'));
    if (stats['goals_scored'] > 0)
      items.add(_StatItem('Goals', '${stats['goals_scored']}'));
    if (stats['assists'] > 0)
      items.add(_StatItem('Assists', '${stats['assists']}'));
    if (stats['clean_sheets'] > 0) items.add(_StatItem('Clean Sheet', '1'));
    if (stats['saves'] > 0) items.add(_StatItem('Saves', '${stats['saves']}'));
    if (stats['yellow_cards'] > 0) items.add(_StatItem('Yellow Card', '1'));
    if (stats['red_cards'] > 0) items.add(_StatItem('Red Card', '1'));
    if (stats['bonus'] > 0) items.add(_StatItem('Bonus', '${stats['bonus']}'));

    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Played 0 mins or no attacking returns yet',
          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardMedium,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              items[i].label,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              items[i].value,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
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
