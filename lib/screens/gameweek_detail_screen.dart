import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/fpl_service.dart';
import '../models/gameweek.dart';
import '../models/player.dart';
import '../models/fixture.dart';
import '../providers/fpl_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'player_detail_screen.dart';
import '../widgets/pitch_view.dart';
import '../widgets/fixture_card.dart';

class GameweekDetailScreen extends StatefulWidget {
  final Gameweek gw;
  final FplProvider provider;

  const GameweekDetailScreen({
    super.key,
    required this.gw,
    required this.provider,
  });

  @override
  State<GameweekDetailScreen> createState() => _GameweekDetailScreenState();
}

class _GameweekDetailScreenState extends State<GameweekDetailScreen> {
  int _activeTab = 0; // 0: Dream Team, 1: Manager Spotlight, 2: Fixtures & Results

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.loadDreamTeam(widget.gw.id);
      widget.provider.loadLiveGwData(widget.gw.id);
      if (widget.gw.highestScoringEntry != null) {
        widget.provider.loadManagerTeam(
          widget.gw.highestScoringEntry!,
          widget.gw.id,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final gw = widget.gw;
    final provider = widget.provider;
    final topPlayer = gw.topElement != null ? provider.getPlayerById(gw.topElement!) : null;
    final mostTransferredPlayer = gw.mostTransferredIn != null ? provider.getPlayerById(gw.mostTransferredIn!) : null;
    final mostCaptainedPlayer = gw.mostCaptained != null ? provider.getPlayerById(gw.mostCaptained!) : null;

    final gwFixtures = provider.fixtures.where((f) => f.event == gw.id).toList();

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(gw.name),
        backgroundColor: AppColors.of(context).secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              provider.loadLiveGwData(gw.id);
              provider.loadDreamTeam(gw.id);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            _buildHeader(context),
            const SizedBox(height: 14),

            // Summary Score Cards (Avg, High, Transfers, Top Scorer)
            _buildSummaryScoreCards(gw, topPlayer),
            const SizedBox(height: 16),

            // Tab Bar Switcher (Dream Team / Manager Spotlight / Fixtures)
            _buildTabSwitcher(context),
            const SizedBox(height: 16),

            // Tab Content
            if (_activeTab == 0)
              _buildDreamTeamSection(context, provider, gw)
            else if (_activeTab == 1)
              _buildManagerSpotlightSection(context, provider, gw)
            else
              _buildFixturesSection(context, provider, gwFixtures),

            const SizedBox(height: 20),

            // Key Highlights
            if (topPlayer != null || mostCaptainedPlayer != null || mostTransferredPlayer != null) ...[
              AppTheme.sectionTitle(context, 'Gameweek Highlights'),
              const SizedBox(height: 12),
              if (topPlayer != null)
                _buildHighlightCard(
                  context,
                  title: 'Top Scorer of the Week',
                  player: topPlayer,
                  team: provider.getTeamById(topPlayer.teamId),
                  pointsText: '${topPlayer.eventPoints} pts',
                  color: const Color(0xFF00FF87),
                  icon: Icons.star_rounded,
                ),
              if (mostCaptainedPlayer != null) ...[
                const SizedBox(height: 8),
                _buildHighlightCard(
                  context,
                  title: 'Most Captained Player',
                  player: mostCaptainedPlayer,
                  team: provider.getTeamById(mostCaptainedPlayer.teamId),
                  pointsText: '${mostCaptainedPlayer.eventPoints} pts',
                  color: const Color(0xFFFBBF24),
                  icon: Icons.shield_rounded,
                ),
              ],
              if (mostTransferredPlayer != null) ...[
                const SizedBox(height: 8),
                _buildHighlightCard(
                  context,
                  title: 'Most Transferred In',
                  player: mostTransferredPlayer,
                  team: provider.getTeamById(mostTransferredPlayer.teamId),
                  pointsText: '${mostTransferredPlayer.eventPoints} pts',
                  color: const Color(0xFF60A5FA),
                  icon: Icons.trending_up_rounded,
                ),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Header Banner ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final gw = widget.gw;
    Color statusColor;
    String statusText;
    if (gw.finished) {
      statusColor = AppColors.of(context).textSecondary;
      statusText = 'Finished';
    } else if (gw.isCurrent) {
      statusColor = AppColors.of(context).primary;
      statusText = 'Live Now';
    } else if (gw.isNext) {
      statusColor = AppColors.of(context).accent;
      statusText = 'Next Up';
    } else {
      statusColor = const Color(0xFFFBBF24);
      statusText = 'Upcoming';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF160D36),
                  AppColors.of(context).cardDark,
                ]
              : [
                  statusColor.withAlpha(20),
                  AppColors.of(context).cardDark,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha(isDark ? 80 : 120)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    gw.name,
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withAlpha(90)),
                    ),
                    child: Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Deadline: ${formatDateTime(gw.deadlineTime)}',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (gw.isCurrent)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.of(context).primary.withAlpha(20),
              ),
              child: Icon(
                Icons.sensors_rounded,
                color: AppColors.of(context).primary,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  // ── Summary Score Cards ────────────────────────────────────────────────────

  Widget _buildSummaryScoreCards(Gameweek gw, Player? topPlayer) {
    final avgScore = gw.averageEntryScore ?? 0;
    final highScore = gw.highestScore ?? 0;
    final transfers = gw.transfersMade;

    return Row(
      children: [
        Expanded(
          child: _statBox(
            'Average Score',
            '$avgScore pts',
            'Overall average',
            Icons.bar_chart_rounded,
            AppColors.of(context).textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            'Highest Score',
            '$highScore pts',
            'Top manager score',
            Icons.emoji_events_rounded,
            const Color(0xFFFBBF24),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            'Transfers Made',
            _formatCount(transfers),
            'Total activity',
            Icons.swap_horiz_rounded,
            const Color(0xFF60A5FA),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Tab Switcher ───────────────────────────────────────────────────────────

  Widget _buildTabSwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabButton('Dream Team', 0, Icons.stadium_rounded),
          _tabButton('Top Manager', 1, Icons.military_tech_rounded),
          _tabButton('Fixtures', 2, Icons.sports_soccer_rounded),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.of(context).primary.withAlpha(30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected
                  ? AppColors.of(context).primary
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? AppColors.of(context).primary
                    : AppColors.of(context).textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.of(context).primary
                      : AppColors.of(context).textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Dream Team Pitch ────────────────────────────────────────────────

  Widget _buildDreamTeamSection(BuildContext context, FplProvider provider, Gameweek gw) {
    final dreamTeamPlayers = provider.getDreamTeam(gw.id);

    if (dreamTeamPlayers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.gradientCard(context: context),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.stadium_outlined, size: 36, color: AppColors.of(context).textSecondary),
              const SizedBox(height: 10),
              Text(
                'Dream Team Not Available Yet',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dream Team is finalized after all matches complete',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final picks = dreamTeamPlayers.asMap().entries.map((e) {
      return {
        'element': e.value.id,
        'position': e.key + 1,
        'is_captain': false,
        'is_vice_captain': false,
        'multiplier': 1,
      };
    }).toList();

    int totalDtPoints = 0;
    for (final p in dreamTeamPlayers) {
      totalDtPoints += provider.getDreamTeamPlayerPoints(gw.id, p.id);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFBBF24).withAlpha(80)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFFBBF24)),
                  SizedBox(width: 6),
                  Text(
                    'Dream Team XI',
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                'Total: $totalDtPoints pts',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        PitchView(
          picks: picks,
          provider: provider,
          gwId: gw.id,
          onPlayerTap: (pick) {
            final p = provider.getPlayerById(pick['element'] as int);
            if (p != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: p)),
              );
            }
          },
        ),
      ],
    );
  }

  // ── Tab 2: Highest Scoring Manager ─────────────────────────────────────────

  Widget _buildManagerSpotlightSection(BuildContext context, FplProvider provider, Gameweek gw) {
    if (gw.highestScoringEntry == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.gradientCard(context: context),
        child: Center(
          child: Text(
            'No manager data recorded for this week',
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ),
      );
    }

    final managerPicks = provider.getManagerTeam(gw.highestScoringEntry!, gw.id);

    return FutureBuilder<Map<String, dynamic>>(
      future: FplService().fetchFplEntry(gw.highestScoringEntry!),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name = data?['name'] ?? 'Top Manager';
        final managerName = '${data?['player_first_name'] ?? ''} ${data?['player_last_name'] ?? ''}'.trim();
        final rawPicks = (managerPicks?['picks'] as List?)
                ?.map((p) => p as Map<String, dynamic>)
                .toList() ??
            [];

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFBBF24).withAlpha(20),
                    AppColors.of(context).cardDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFBBF24).withAlpha(80)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.military_tech_rounded, color: Color(0xFFFBBF24), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          managerName.isNotEmpty ? managerName : 'Highest Scorer',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${gw.highestScore ?? 0} PTS',
                      style: const TextStyle(
                        color: Color(0xFF0C0720),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (rawPicks.isNotEmpty) ...[
              const SizedBox(height: 12),
              PitchView(
                picks: rawPicks,
                provider: provider,
                gwId: gw.id,
                onPlayerTap: (pick) {
                  final p = provider.getPlayerById(pick['element'] as int);
                  if (p != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: p)),
                    );
                  }
                },
              ),
            ],
          ],
        );
      },
    );
  }

  // ── Tab 3: Fixtures & Results ──────────────────────────────────────────────

  Widget _buildFixturesSection(BuildContext context, FplProvider provider, List<Fixture> fixtures) {
    if (fixtures.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.gradientCard(context: context),
        child: Center(
          child: Text(
            'No fixtures scheduled for this gameweek',
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: fixtures.map((f) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: FixtureCard(
            fixture: f,
            provider: provider,
          ),
        );
      }).toList(),
    );
  }

  // ── Highlight Card Helper ──────────────────────────────────────────────────

  Widget _buildHighlightCard(
    BuildContext context, {
    required String title,
    required Player player,
    required dynamic team,
    required String pointsText,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.of(context).cardMedium,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withAlpha(90)),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: player.photoUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Icon(Icons.person, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${player.webName} (${team?.shortName ?? ''})',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withAlpha(90)),
              ),
              child: Text(
                pointsText,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
