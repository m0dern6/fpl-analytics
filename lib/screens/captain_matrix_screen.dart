import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'player_detail_screen.dart';

class CaptainMatrixScreen extends StatelessWidget {
  const CaptainMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final currentGw = provider.currentGameweek?.id ?? 1;

        // Rank captain contenders by composite Captaincy Rating Algorithm
        final contenders = provider.players.where((p) {
          final form = double.tryParse(p.form) ?? 0.0;
          final totalPts = p.totalPoints;
          return form >= 4.0 || totalPts >= 50 || p.selectedByPercent.compareTo('15.0') >= 0;
        }).map((p) {
          final form = double.tryParse(p.form) ?? 0.0;
          final ownership = double.tryParse(p.selectedByPercent) ?? 0.0;
          final ict = double.tryParse(p.ictIndex) ?? 0.0;
          final ptsPerGame = double.tryParse(p.pointsPerGame) ?? 0.0;

          // Composite captaincy rating score (0 - 100)
          final score = ((form * 4.5) + (ptsPerGame * 5.0) + (ict * 0.18) + (ownership * 0.35)).clamp(10.0, 99.9);
          return _CaptainContender(player: p, score: score, form: form, ownership: ownership);
        }).toList()
          ..sort((a, b) => b.score.compareTo(a.score));

        final topThree = contenders.take(3).toList();

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Captaincy Decider Matrix'),
            backgroundColor: AppColors.of(context).secondary,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFBBF24).withAlpha(80)),
                ),
                child: Text(
                  'GW$currentGw Pick',
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Captaincy Podium
                _buildPodiumHeader(context, topThree, provider),
                const SizedBox(height: 20),

                // All Contenders Table / Matrix
                AppTheme.sectionTitle(context, 'Captaincy Comparison Matrix'),
                const SizedBox(height: 12),
                ...contenders.take(12).map((c) {
                  final rank = contenders.indexOf(c) + 1;
                  return _buildContenderCard(context, provider, c, rank)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: rank * 30));
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Podium Header ──────────────────────────────────────────────────────────

  Widget _buildPodiumHeader(
    BuildContext context,
    List<_CaptainContender> topThree,
    FplProvider provider,
  ) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E143C),
            Color(0xFF0F0B24),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFBBF24).withAlpha(80), width: 1.2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 18),
              SizedBox(width: 6),
              Text(
                'Top Recommended Captains',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 2nd Place
              if (topThree.length > 1)
                _buildPodiumPillar(context, provider, topThree[1], 2, '🥈 #2 Pick', const Color(0xFF94A3B8), 100),
              // 1st Place
              if (topThree.isNotEmpty)
                _buildPodiumPillar(context, provider, topThree[0], 1, '👑 Best Pick', const Color(0xFFFBBF24), 120),
              // 3rd Place
              if (topThree.length > 2)
                _buildPodiumPillar(context, provider, topThree[2], 3, '🥉 #3 Pick', const Color(0xFFF97316), 85),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar(
    BuildContext context,
    FplProvider provider,
    _CaptainContender contender,
    int rank,
    String badgeTitle,
    Color badgeColor,
    double height,
  ) {
    final player = contender.player;
    final team = provider.getTeamById(player.teamId);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
      ),
      child: Column(
        children: [
          // Photo
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.of(context).cardMedium,
                  border: Border.all(color: badgeColor, width: rank == 1 ? 2.5 : 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: player.photoUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorWidget: (_, _, _) => const Icon(Icons.person),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Color(0xFF0C0720),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            player.webName,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
          ),
          Text(
            team?.shortName ?? '',
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withAlpha(90)),
            ),
            child: Text(
              '${contender.score.toStringAsFixed(1)} Score',
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contender Card ─────────────────────────────────────────────────────────

  Widget _buildContenderCard(
    BuildContext context,
    FplProvider provider,
    _CaptainContender contender,
    int rank,
  ) {
    final player = contender.player;
    final team = provider.getTeamById(player.teamId);
    final posColor = getPositionColor(player.elementType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.gradientCard(context: context),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank <= 3 ? const Color(0xFFFBBF24) : AppColors.of(context).textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Photo
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.of(context).cardMedium,
                      border: Border.all(color: posColor.withAlpha(80)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: player.photoUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorWidget: (_, _, _) => const Icon(Icons.person, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              player.webName,
                              style: TextStyle(
                                color: AppColors.of(context).textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: posColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                getPositionShort(player.elementType),
                                style: TextStyle(
                                  color: posColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${team?.name ?? ''} • ${formatPrice(player.nowCost)} • ${player.selectedByPercent}% EO',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Captain Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFBBF24).withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          contender.score.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'AI RATING',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Metrics Breakdown Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricPill(context, 'Form', player.form, const Color(0xFF00FF87)),
                  _metricPill(context, 'PPG', player.pointsPerGame, const Color(0xFF60A5FA)),
                  _metricPill(context, 'Total Pts', '${player.totalPoints}', AppColors.of(context).textPrimary),
                  _metricPill(context, 'ICT Index', player.ictIndex, const Color(0xFFF97316)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricPill(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Text(
            ' ',
          ),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptainContender {
  final Player player;
  final double score;
  final double form;
  final double ownership;

  _CaptainContender({
    required this.player,
    required this.score,
    required this.form,
    required this.ownership,
  });
}
