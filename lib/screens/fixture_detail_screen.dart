import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/fixture.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../providers/fpl_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/difficulty_badge.dart';
import 'player_detail_screen.dart';

enum LineupViewMode { pitch, list }

class FixtureDetailScreen extends StatefulWidget {
  final Fixture fixture;
  final Team? homeTeam;
  final Team? awayTeam;

  const FixtureDetailScreen({
    super.key,
    required this.fixture,
    this.homeTeam,
    this.awayTeam,
  });

  @override
  State<FixtureDetailScreen> createState() => _FixtureDetailScreenState();
}

class _FixtureDetailScreenState extends State<FixtureDetailScreen> {
  Timer? _liveTimer;
  LineupViewMode _viewMode = LineupViewMode.pitch;
  bool _showHomeTeamLineup = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestData();
    _startLiveTimer();
  }

  void _fetchLatestData() {
    final event = widget.fixture.event;
    if (event != null) {
      final provider = context.read<FplProvider>();
      provider.loadLiveGwData(event);
      if (widget.fixture.isLive) {
        provider.updateFixturesForGameweek(event);
      }
    }
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final provider = context.read<FplProvider>();
      final event = widget.fixture.event;
      if (event == null) return;
      final currentFixture = provider.fixtures.firstWhere(
        (f) => f.id == widget.fixture.id,
        orElse: () => widget.fixture,
      );
      if (currentFixture.isLive) {
        provider.updateFixturesForGameweek(event);
        provider.loadLiveGwData(event);
      }
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final currentFixture = provider.fixtures.firstWhere(
          (f) => f.id == widget.fixture.id,
          orElse: () => widget.fixture,
        );

        final home = widget.homeTeam ??
            provider.getTeamById(currentFixture.homeTeamId);
        final away = widget.awayTeam ??
            provider.getTeamById(currentFixture.awayTeamId);

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: Text(
              currentFixture.event != null
                  ? 'Gameweek ${currentFixture.event}'
                  : 'Fixture',
            ),
            backgroundColor: AppColors.of(context).secondary,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMatchCard(context, provider, currentFixture, home, away),
                const SizedBox(height: 16),
                _buildLineupSection(
                    context, provider, currentFixture, home, away),
                if ((currentFixture.isFinished || currentFixture.isLive) &&
                    currentFixture.stats.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildMatchEventsCard(
                      context, provider, currentFixture, home, away),
                ],
                const SizedBox(height: 16),
                _buildMatchStatsSummaryCard(context, currentFixture),
                const SizedBox(height: 16),
                _buildDifficultyCard(context, currentFixture, home, away),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Scorecard & Goal Scorers / Assisters ───────────────────────────────────

  Widget _buildMatchCard(
    BuildContext context,
    FplProvider provider,
    Fixture fixture,
    Team? home,
    Team? away,
  ) {
    final isLive = fixture.isLive;
    final isFinished = fixture.isFinished;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    BoxDecoration decoration;
    if (isLive) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withAlpha(90),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (isFinished) {
      decoration = BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          width: 1,
        ),
      );
    } else {
      decoration = AppTheme.purpleGradient();
    }

    final textColor = (isLive || !isFinished)
        ? Colors.white
        : AppColors.of(context).textPrimary;
    final subtextColor = (isLive || !isFinished)
        ? Colors.white.withAlpha(200)
        : AppColors.of(context).textSecondary;

    // Goal scorers and assisters data
    final homeGoalEvents = _extractGoalEvents(provider, fixture, isHome: true);
    final awayGoalEvents = _extractGoalEvents(provider, fixture, isHome: false);
    final hasGoals = homeGoalEvents.isNotEmpty || awayGoalEvents.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: decoration,
      child: Column(
        children: [
          if (fixture.event != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isLive
                    ? Colors.white.withAlpha(40)
                    : AppColors.of(context).primary.withAlpha(24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLive
                      ? Colors.white.withAlpha(80)
                      : AppColors.of(context).primary.withAlpha(80),
                ),
              ),
              child: Text(
                'Gameweek ${fixture.event}',
                style: TextStyle(
                  color: isLive ? Colors.white : AppColors.of(context).primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _teamColumn(
                  context,
                  home,
                  isHome: true,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: (isLive || isFinished || fixture.hasResult)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${fixture.homeTeamScore ?? 0}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '–',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Text(
                            '${fixture.awayTeamScore ?? 0}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text(
                            'VS',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          if (fixture.kickoffTime != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              formatTimeShort(fixture.kickoffTime),
                              style: TextStyle(
                                color: isLive
                                    ? Colors.white
                                    : AppColors.of(context).primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              Expanded(
                child: _teamColumn(
                  context,
                  away,
                  isHome: false,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 14),
          if (isFinished) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Full Time',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else if (isLive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Color(0xFFE91E63), size: 8),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE • ${_formatMatchMinute(fixture)}',
                    style: const TextStyle(
                      color: Color(0xFFE91E63),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (fixture.kickoffTime != null) ...[
            Text(
              formatDateTime(fixture.kickoffTime),
              style: TextStyle(
                color: subtextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // ── Goal Scorers and Assisters in Requested Structure ─────────────
          if (hasGoals) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(isLive ? 50 : 35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withAlpha(30),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Home Goals
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (homeGoalEvents.isEmpty)
                          const SizedBox.shrink()
                        else
                          ...homeGoalEvents.map(
                            (g) => _buildGoalScorerEntry(g, isLeft: true, textColor: textColor, subtextColor: subtextColor),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Away Goals
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (awayGoalEvents.isEmpty)
                          const SizedBox.shrink()
                        else
                          ...awayGoalEvents.map(
                            (g) => _buildGoalScorerEntry(g, isLeft: false, textColor: textColor, subtextColor: subtextColor),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalScorerEntry(
    _GoalEventData data, {
    required bool isLeft,
    required Color textColor,
    required Color subtextColor,
  }) {
    final eventColor = data.isOwnGoal ? const Color(0xFFEF4444) : textColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment:
            isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: isLeft
                ? [
                    Icon(
                      data.isOwnGoal
                          ? Icons.sports_soccer_outlined
                          : Icons.sports_soccer,
                      size: 13,
                      color: eventColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        data.label,
                        style: TextStyle(
                          color: eventColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]
                : [
                    Flexible(
                      child: Text(
                        data.label,
                        style: TextStyle(
                          color: eventColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      data.isOwnGoal
                          ? Icons.sports_soccer_outlined
                          : Icons.sports_soccer,
                      size: 13,
                      color: eventColor,
                    ),
                  ],
          ),
          if (data.assisterName != null && data.assisterName!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: isLeft ? 17 : 0, right: isLeft ? 0 : 17),
              child: Text(
                '(${data.assisterName})',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_GoalEventData> _extractGoalEvents(
    FplProvider provider,
    Fixture fixture, {
    required bool isHome,
  }) {
    final events = <_GoalEventData>[];

    // Goals scored
    final goalsStat =
        fixture.stats.where((s) => s.identifier == 'goals_scored').firstOrNull;
    final assistsStat =
        fixture.stats.where((s) => s.identifier == 'assists').firstOrNull;
    final ownGoalsStat =
        fixture.stats.where((s) => s.identifier == 'own_goals').firstOrNull;

    final goalEntries = isHome ? (goalsStat?.home ?? []) : (goalsStat?.away ?? []);
    final assistEntries = isHome ? (assistsStat?.home ?? []) : (assistsStat?.away ?? []);
    final ownGoalEntries = isHome ? (ownGoalsStat?.away ?? []) : (ownGoalsStat?.home ?? []);

    // Create a list of assister names available to pair
    final assisterNames = <String>[];
    for (final a in assistEntries) {
      final p = provider.getPlayerById(a.element);
      if (p != null) {
        for (int i = 0; i < a.value; i++) {
          assisterNames.add(p.webName);
        }
      }
    }

    int assistIndex = 0;

    for (final g in goalEntries) {
      final scorer = provider.getPlayerById(g.element);
      final scorerName = scorer?.webName ?? 'Player #${g.element}';

      String? assister;
      if (assistIndex < assisterNames.length) {
        assister = assisterNames[assistIndex];
        assistIndex += g.value;
      }

      events.add(
        _GoalEventData(
          scorerName: scorerName,
          count: g.value,
          assisterName: assister,
          isOwnGoal: false,
        ),
      );
    }

    // Add own goals
    for (final og in ownGoalEntries) {
      final scorer = provider.getPlayerById(og.element);
      final scorerName = scorer?.webName ?? 'Player #${og.element}';
      events.add(
        _GoalEventData(
          scorerName: scorerName,
          count: og.value,
          assisterName: null,
          isOwnGoal: true,
        ),
      );
    }

    return events;
  }

  String _formatMatchMinute(Fixture fixture) {
    if (fixture.minutes != null && fixture.minutes! > 0) {
      if (fixture.minutes == 45) return 'HT';
      if (fixture.minutes! > 90) return '90+\'';
      return '${fixture.minutes}\'';
    }
    if (fixture.kickoffDateTime != null) {
      final elapsed = DateTime.now()
          .toUtc()
          .difference(fixture.kickoffDateTime!.toUtc())
          .inMinutes;
      if (elapsed <= 0) return '1\'';
      if (elapsed <= 45) return '$elapsed\'';
      if (elapsed <= 60) return 'HT';
      final secondHalfMin = (elapsed - 15).clamp(46, 90);
      return '$secondHalfMin\'';
    }
    return 'LIVE';
  }

  Widget _teamColumn(
    BuildContext context,
    Team? team, {
    required bool isHome,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: team?.badgeUrl ?? '',
          width: 54,
          height: 54,
          fit: BoxFit.contain,
          placeholder: (_, _) => Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.of(context).cardMedium,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shield,
              color: AppColors.of(context).textSecondary,
              size: 28,
            ),
          ),
          errorWidget: (_, _, _) => Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.of(context).cardMedium,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                team?.shortName ?? '?',
                style: TextStyle(
                  color: AppColors.of(context).primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          team?.shortName ?? '?',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          team?.name ?? '',
          style: TextStyle(
            color: subtextColor,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isHome
                ? AppColors.of(context).primary.withAlpha(30)
                : AppColors.of(context).accent.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHome
                  ? AppColors.of(context).primary.withAlpha(90)
                  : AppColors.of(context).accent.withAlpha(90),
            ),
          ),
          child: Text(
            isHome ? 'Home' : 'Away',
            style: TextStyle(
              color: isHome
                  ? AppColors.of(context).primary
                  : AppColors.of(context).accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Lineup Section (Pitch View vs List View) ──────────────────────────────

  Widget _buildLineupSection(
    BuildContext context,
    FplProvider provider,
    Fixture fixture,
    Team? home,
    Team? away,
  ) {
    if (fixture.isUpcoming) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.gradientCard(context: context),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              color: AppColors.of(context).textSecondary,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              'Starting Lineup',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lineups available after kickoff.',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms);
    }

    final homeLineup = _buildTeamLineupData(provider, fixture, fixture.homeTeamId);
    final awayLineup = _buildTeamLineupData(provider, fixture, fixture.awayTeamId);

    if (homeLineup.startingXI.isEmpty && awayLineup.startingXI.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.gradientCard(context: context),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              color: AppColors.of(context).textSecondary,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              'Lineup Data',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lineup details being processed...',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final selectedLineup = _showHomeTeamLineup ? homeLineup : awayLineup;
    final selectedTeam = _showHomeTeamLineup ? home : away;

    return Container(
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Pitch View vs List View switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Team Lineups',
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Pitch vs List view toggle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).cardMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildViewToggleBtn(
                        title: 'Pitch',
                        icon: Icons.stadium_rounded,
                        isSelected: _viewMode == LineupViewMode.pitch,
                        onTap: () => setState(() => _viewMode = LineupViewMode.pitch),
                      ),
                      _buildViewToggleBtn(
                        title: 'List',
                        icon: Icons.list_alt_rounded,
                        isSelected: _viewMode == LineupViewMode.list,
                        onTap: () => setState(() => _viewMode = LineupViewMode.list),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Team Selector Bar (Home vs Away)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.of(context).cardMedium,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTeamTabBtn(
                    title: home?.shortName ?? 'Home',
                    badgeUrl: home?.badgeUrl,
                    isSelected: _showHomeTeamLineup,
                    color: AppColors.of(context).primary,
                    onTap: () => setState(() => _showHomeTeamLineup = true),
                  ),
                ),
                Expanded(
                  child: _buildTeamTabBtn(
                    title: away?.shortName ?? 'Away',
                    badgeUrl: away?.badgeUrl,
                    isSelected: !_showHomeTeamLineup,
                    color: AppColors.of(context).accent,
                    onTap: () => setState(() => _showHomeTeamLineup = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Render Selected View
          if (_viewMode == LineupViewMode.pitch)
            _buildPitchLineupView(context, provider, selectedLineup, selectedTeam, fixture)
          else
            _buildCategorizedListLineupView(context, provider, selectedLineup, selectedTeam, fixture),

          const SizedBox(height: 12),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildViewToggleBtn({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.of(context).primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? const Color(0xFF0C0720)
                  : AppColors.of(context).textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF0C0720)
                    : AppColors.of(context).textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamTabBtn({
    required String title,
    String? badgeUrl,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (badgeUrl != null)
              CachedNetworkImage(
                imageUrl: badgeUrl,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : AppColors.of(context).textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pitch Lineup View ──────────────────────────────────────────────────────

  Widget _buildPitchLineupView(
    BuildContext context,
    FplProvider provider,
    _TeamLineupData lineup,
    Team? team,
    Fixture fixture,
  ) {
    final gk = lineup.startingXI.where((p) => p.player.elementType == 1).toList();
    final def = lineup.startingXI.where((p) => p.player.elementType == 2).toList();
    final mid = lineup.startingXI.where((p) => p.player.elementType == 3).toList();
    final fwd = lineup.startingXI.where((p) => p.player.elementType == 4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Formation summary header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.of(context).cardMedium,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Formation: ${def.length}-${mid.length}-${fwd.length}',
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${lineup.startingXI.length} Starters',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Pitch Container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Pitch Background
                Positioned.fill(
                  child: CustomPaint(painter: _PitchFieldPainter()),
                ),
                // Pitch Players in Rows
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    children: [
                      _buildPitchRow(context, gk),
                      const SizedBox(height: 12),
                      _buildPitchRow(context, def),
                      const SizedBox(height: 12),
                      _buildPitchRow(context, mid),
                      const SizedBox(height: 12),
                      _buildPitchRow(context, fwd),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Substituted In & Bench Section under Pitch
          if (lineup.substitutedIn.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildPitchSubsSection(context, 'Substituted Players', lineup.substitutedIn, true),
          ],
          if (lineup.bench.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildPitchSubsSection(context, 'Bench / Reserves', lineup.bench, false),
          ],
        ],
      ),
    );
  }

  Widget _buildPitchRow(BuildContext context, List<_LineupPlayerItem> players) {
    if (players.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: players.map((p) => _buildPitchPlayerCard(context, p)).toList(),
    );
  }

  Widget _buildPitchPlayerCard(BuildContext context, _LineupPlayerItem item) {
    final player = item.player;
    final posColor = getPositionColor(player.elementType);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Player Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  border: Border.all(color: posColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(90),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: player.photoUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorWidget: (_, _, _) => const Icon(Icons.person, size: 20, color: Colors.white70),
                ),
              ),
              // Substituted Out Badge Indicator
              if (item.subbedOffMin != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.white, size: 8),
                        Text(
                          '${item.subbedOffMin}\'',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          // Name Tag with official points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(180),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.webName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.points} pts • ${item.minsPlayed}\'',
                  style: TextStyle(
                    color: item.points >= 6
                        ? const Color(0xFF00E5A0)
                        : Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchSubsSection(
    BuildContext context,
    String title,
    List<_LineupPlayerItem> players,
    bool isSubbedIn,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSubbedIn ? Icons.swap_horiz_rounded : Icons.chair_rounded,
                size: 14,
                color: isSubbedIn ? const Color(0xFF34D399) : AppColors.of(context).textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSubbedIn ? const Color(0xFF34D399) : AppColors.of(context).textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: players.map((item) {
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: item.player)),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSubbedIn
                          ? const Color(0xFF34D399).withAlpha(80)
                          : AppColors.of(context).divider,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSubbedIn) ...[
                        const Icon(Icons.arrow_upward, size: 10, color: Color(0xFF34D399)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        item.player.webName,
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.points} pts',
                        style: TextStyle(
                          color: item.points >= 6
                              ? AppColors.of(context).primary
                              : AppColors.of(context).textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isSubbedIn && item.subbedForPlayerName != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(for ${item.subbedForPlayerName})',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Categorized List Lineup View ──────────────────────────────────────────

  Widget _buildCategorizedListLineupView(
    BuildContext context,
    FplProvider provider,
    _TeamLineupData lineup,
    Team? team,
    Fixture fixture,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Starting XI Section
          _buildListSectionHeader(context, 'Starting Lineup (Starting XI)', lineup.startingXI.length, AppColors.of(context).primary),
          const SizedBox(height: 8),
          ...lineup.startingXI.map((item) => _buildListPlayerRow(context, item, isStarter: true)),

          // 2. Substituted In Section
          if (lineup.substitutedIn.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildListSectionHeader(context, 'Substituted In', lineup.substitutedIn.length, const Color(0xFF34D399)),
            const SizedBox(height: 8),
            ...lineup.substitutedIn.map((item) => _buildListPlayerRow(context, item, isSubIn: true)),
          ],

          // 3. Bench / Reserves Section
          if (lineup.bench.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildListSectionHeader(context, 'Bench / Unused Substitutes', lineup.bench.length, AppColors.of(context).textSecondary),
            const SizedBox(height: 8),
            ...lineup.bench.map((item) => _buildListPlayerRow(context, item, isBench: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildListSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '$count players',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListPlayerRow(
    BuildContext context,
    _LineupPlayerItem item, {
    bool isStarter = false,
    bool isSubIn = false,
    bool isBench = false,
  }) {
    final player = item.player;
    final posColor = getPositionColor(player.elementType);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardMedium.withAlpha(60),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Photo with position badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.of(context).cardMedium,
                border: Border.all(color: posColor.withAlpha(100)),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: player.photoUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const Icon(Icons.person, size: 16),
              ),
            ),
            const SizedBox(width: 10),
            // Player details & substitution info
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: posColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          getPositionShort(player.elementType),
                          style: TextStyle(
                            color: posColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (isStarter && item.subbedOffMin != null)
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward, size: 11, color: Color(0xFFEF4444)),
                        const SizedBox(width: 3),
                        Text(
                          'Subbed off: ${item.subbedOffMin}\'${item.subbedForPlayerName != null ? ' (for ${item.subbedForPlayerName})' : ''}',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else if (isSubIn)
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward, size: 11, color: Color(0xFF34D399)),
                        const SizedBox(width: 3),
                        Text(
                          'Subbed on: ${item.minsPlayed}\' played${item.subbedForPlayerName != null ? ' (for ${item.subbedForPlayerName})' : ''}',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      isBench ? 'Unused Sub' : '${item.minsPlayed}\' played',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            // Official Points Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.points >= 6
                    ? AppColors.of(context).primary.withAlpha(25)
                    : AppColors.of(context).cardMedium,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.points >= 6
                      ? AppColors.of(context).primary.withAlpha(80)
                      : AppColors.of(context).divider,
                ),
              ),
              child: Text(
                '${item.points} pts',
                style: TextStyle(
                  color: item.points >= 6
                      ? AppColors.of(context).primary
                      : AppColors.of(context).textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lineup Data Extraction & Pairing ──────────────────────────────────────

  _TeamLineupData _buildTeamLineupData(
    FplProvider provider,
    Fixture fixture,
    int teamId,
  ) {
    final teamPlayers = provider.players.where((p) => p.teamId == teamId).toList();
    final event = fixture.event ?? 1;

    final playedPlayers = <_LineupPlayerItem>[];
    final unplayedPlayers = <_LineupPlayerItem>[];

    for (final p in teamPlayers) {
      final liveStats = provider.getLiveStatsForPlayer(p.id, gw: event);
      final mins = liveStats?['minutes'] as int? ?? 0;
      final points = liveStats?['total_points'] as int? ?? provider.getPlayerPointsForGameweek(p.id, event);

      final item = _LineupPlayerItem(
        player: p,
        minsPlayed: mins,
        points: points,
      );

      if (mins > 0) {
        playedPlayers.add(item);
      } else {
        unplayedPlayers.add(item);
      }
    }

    // Determine Starting XI (11 players with highest mins / valid formation)
    final startingXI = <_LineupPlayerItem>[];
    final subbedIn = <_LineupPlayerItem>[];

    if (playedPlayers.length <= 11) {
      startingXI.addAll(playedPlayers);
    } else {
      // Group played players by position
      final gks = playedPlayers.where((p) => p.player.elementType == 1).toList()
        ..sort((a, b) => b.minsPlayed.compareTo(a.minsPlayed));
      final defs = playedPlayers.where((p) => p.player.elementType == 2).toList()
        ..sort((a, b) => b.minsPlayed.compareTo(a.minsPlayed));
      final mids = playedPlayers.where((p) => p.player.elementType == 3).toList()
        ..sort((a, b) => b.minsPlayed.compareTo(a.minsPlayed));
      final fwds = playedPlayers.where((p) => p.player.elementType == 4).toList()
        ..sort((a, b) => b.minsPlayed.compareTo(a.minsPlayed));

      // 1. Mandatory GK (1)
      if (gks.isNotEmpty) {
        startingXI.add(gks.first);
      }

      // 2. Minimum positional constraints: min 3 DEF, min 2 MID, min 1 FWD (if available)
      final minDefs = defs.take(3).toList();
      final minMids = mids.take(2).toList();
      final minFwds = fwds.take(1).toList();

      startingXI.addAll(minDefs);
      startingXI.addAll(minMids);
      startingXI.addAll(minFwds);

      final chosenIds = startingXI.map((e) => e.player.id).toSet();

      // 3. Pool remaining outfield candidates sorted by minutes played (and points)
      final remainingOutfielders = playedPlayers
          .where((p) => p.player.elementType != 1 && !chosenIds.contains(p.player.id))
          .toList()
        ..sort((a, b) {
          final m = b.minsPlayed.compareTo(a.minsPlayed);
          if (m != 0) return m;
          return b.points.compareTo(a.points);
        });

      // 4. Fill remaining spots up to 11 while respecting max limits (DEF <= 5, MID <= 5, FWD <= 3)
      for (final cand in remainingOutfielders) {
        if (startingXI.length >= 11) break;
        final currentDefs = startingXI.where((p) => p.player.elementType == 2).length;
        final currentMids = startingXI.where((p) => p.player.elementType == 3).length;
        final currentFwds = startingXI.where((p) => p.player.elementType == 4).length;

        if (cand.player.elementType == 2 && currentDefs < 5) {
          startingXI.add(cand);
          chosenIds.add(cand.player.id);
        } else if (cand.player.elementType == 3 && currentMids < 5) {
          startingXI.add(cand);
          chosenIds.add(cand.player.id);
        } else if (cand.player.elementType == 4 && currentFwds < 3) {
          startingXI.add(cand);
          chosenIds.add(cand.player.id);
        }
      }

      // Fallback if still under 11
      if (startingXI.length < 11) {
        for (final cand in remainingOutfielders) {
          if (startingXI.length >= 11) break;
          if (!chosenIds.contains(cand.player.id)) {
            startingXI.add(cand);
            chosenIds.add(cand.player.id);
          }
        }
      }

      // All remaining played players are Substituted In
      for (final p in playedPlayers) {
        if (!chosenIds.contains(p.player.id)) {
          subbedIn.add(p);
        }
      }
    }

    // Sort Starting XI by position
    startingXI.sort((a, b) => a.player.elementType.compareTo(b.player.elementType));

    // Detect Substituted Off starters and pair with Substituted In players
    final subbedOffStarters = startingXI.where((p) => p.minsPlayed < 90 && p.minsPlayed > 0).toList()
      ..sort((a, b) => a.minsPlayed.compareTo(b.minsPlayed));

    for (int i = 0; i < subbedOffStarters.length; i++) {
      final starter = subbedOffStarters[i];
      starter.subbedOffMin = starter.minsPlayed;

      if (i < subbedIn.length) {
        final sub = subbedIn[i];
        starter.subbedForPlayerName = sub.player.webName;
        sub.subbedForPlayerName = starter.player.webName;
      }
    }

    return _TeamLineupData(
      startingXI: startingXI,
      substitutedIn: subbedIn,
      bench: unplayedPlayers,
    );
  }

  // ── Match Events (Official API Points) ────────────────────────────────────

  Widget _buildMatchEventsCard(
    BuildContext context,
    FplProvider provider,
    Fixture fixture,
    Team? home,
    Team? away,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Events',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...fixture.stats
              .where((s) => s.home.isNotEmpty || s.away.isNotEmpty)
              .map((stat) => _buildStatSection(context, provider, stat, fixture, home, away)),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildStatSection(
    BuildContext context,
    FplProvider provider,
    FixtureStat stat,
    Fixture fixture,
    Team? home,
    Team? away,
  ) {
    final info = _statInfo(context, stat.identifier);
    if (info == null) return const SizedBox.shrink();

    final allEntries = [
      ...stat.home.map((e) => _StatDisplayEntry(e, isHome: true)),
      ...stat.away.map((e) => _StatDisplayEntry(e, isHome: false)),
    ];

    if (allEntries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(info.icon, color: info.color, size: 16),
              const SizedBox(width: 8),
              Text(
                info.label,
                style: TextStyle(
                  color: info.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ...allEntries.map(
          (entry) => _buildPlayerEventRow(context, provider, entry, stat.identifier, info, fixture, home, away),
        ),
        Divider(color: AppColors.of(context).divider, height: 16),
      ],
    );
  }

  Widget _buildPlayerEventRow(
    BuildContext context,
    FplProvider provider,
    _StatDisplayEntry entry,
    String identifier,
    _StatMeta info,
    Fixture fixture,
    Team? home,
    Team? away,
  ) {
    final player = provider.getPlayerById(entry.stat.element);
    final teamName = entry.isHome
        ? (home?.shortName ?? 'Home')
        : (away?.shortName ?? 'Away');
    final teamColor = entry.isHome
        ? AppColors.of(context).primary
        : AppColors.of(context).accent;

    // Resolve exact official FPL API points (e.g. 5 pts for Midfielder goal, 6 pts for Defender goal)
    final officialPoints = provider.getOfficialStatPoints(
      entry.stat.element,
      identifier,
      fixtureId: fixture.id,
      gw: fixture.event,
    );

    final totalStatPoints = officialPoints != 0
        ? officialPoints
        : (info.pointsEach != null ? entry.stat.value * info.pointsEach! : null);

    return InkWell(
      onTap: player != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerDetailScreen(player: player),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.of(context).cardMedium,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: teamColor.withAlpha(100)),
              ),
              clipBehavior: Clip.antiAlias,
              child: player != null
                  ? CachedNetworkImage(
                      imageUrl: player.photoUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      placeholder: (_, _) => Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 18,
                      ),
                      errorWidget: (_, _, _) => Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 18,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: AppColors.of(context).textSecondary,
                      size: 18,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player?.webName ?? 'Player #${entry.stat.element}',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    teamName,
                    style: TextStyle(color: teamColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: info.color.withAlpha(24),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: info.color.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(info.icon, color: info.color, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    _formatValue(entry.stat),
                    style: TextStyle(
                      color: info.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (totalStatPoints != null && totalStatPoints != 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: totalStatPoints > 0
                      ? AppColors.of(context).warning.withAlpha(24)
                      : AppColors.of(context).error.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: totalStatPoints > 0
                        ? AppColors.of(context).warning.withAlpha(80)
                        : AppColors.of(context).error.withAlpha(80),
                  ),
                ),
                child: Text(
                  '${totalStatPoints > 0 ? '+' : ''}$totalStatPoints pts',
                  style: TextStyle(
                    color: totalStatPoints > 0
                        ? AppColors.of(context).warning
                        : AppColors.of(context).error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchStatsSummaryCard(BuildContext context, Fixture fixture) {
    int totalGoals = 0;
    int totalYellow = 0;
    int totalRed = 0;
    int totalSaves = 0;

    for (final s in fixture.stats) {
      final total = [...s.home, ...s.away].fold(0, (sum, e) => sum + e.value);
      if (s.identifier == 'goals_scored') totalGoals = total;
      if (s.identifier == 'yellow_cards') totalYellow = total;
      if (s.identifier == 'red_cards') totalRed = total;
      if (s.identifier == 'saves') totalSaves = total;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Summary',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statSummaryBadge(context, 'Goals', '$totalGoals',
                  Icons.sports_soccer_rounded, AppColors.of(context).primary),
              _statSummaryBadge(context, 'Yellows', '$totalYellow',
                  Icons.square_rounded, AppColors.of(context).warning),
              _statSummaryBadge(context, 'Reds', '$totalRed',
                  Icons.square_rounded, AppColors.of(context).error),
              _statSummaryBadge(context, 'Saves', '$totalSaves',
                  Icons.back_hand_rounded, const Color(0xFF60A5FA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statSummaryBadge(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 16,
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

  String _formatValue(FixtureStatEntry stat) {
    if (stat.value == 1) return '×1';
    return '×${stat.value}';
  }

  _StatMeta? _statInfo(BuildContext context, String identifier) {
    switch (identifier) {
      case 'goals_scored':
        return _StatMeta(
          label: 'Goals Scored',
          icon: Icons.sports_soccer_rounded,
          color: AppColors.of(context).primary,
          pointsEach: null, // Sourced from official API
        );
      case 'assists':
        return const _StatMeta(
          label: 'Assists',
          icon: Icons.sports_rounded,
          color: Color(0xFF8B5CF6),
          pointsEach: 3,
        );
      case 'own_goals':
        return const _StatMeta(
          label: 'Own Goals',
          icon: Icons.sports_soccer_outlined,
          color: Color(0xFFEF4444),
          pointsEach: -2,
        );
      case 'penalties_saved':
        return const _StatMeta(
          label: 'Penalties Saved',
          icon: Icons.back_hand_outlined,
          color: Color(0xFF10B981),
          pointsEach: 5,
        );
      case 'penalties_missed':
        return const _StatMeta(
          label: 'Penalties Missed',
          icon: Icons.block_rounded,
          color: Color(0xFFF43F5E),
          pointsEach: -2,
        );
      case 'yellow_cards':
        return const _StatMeta(
          label: 'Yellow Cards',
          icon: Icons.square_rounded,
          color: Color(0xFFF59E0B),
          pointsEach: -1,
        );
      case 'red_cards':
        return const _StatMeta(
          label: 'Red Cards',
          icon: Icons.square_rounded,
          color: Color(0xFFDC2626),
          pointsEach: -3,
        );
      case 'saves':
        return const _StatMeta(
          label: 'Saves',
          icon: Icons.back_hand_rounded,
          color: Color(0xFF38BDF8),
          pointsEach: null,
        );
      case 'bonus':
        return const _StatMeta(
          label: 'Bonus Points',
          icon: Icons.add_circle_rounded,
          color: Color(0xFFFBBF24),
          pointsEach: 1,
        );
      case 'bps':
        return _StatMeta(
          label: 'Bonus Point System (BPS)',
          icon: Icons.bar_chart_rounded,
          color: AppColors.of(context).textSecondary,
          pointsEach: null,
        );
      default:
        return null;
    }
  }

  Widget _buildDifficultyCard(
    BuildContext context,
    Fixture fixture,
    Team? home,
    Team? away,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fixture Difficulty',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _difficultyRow(
                  context,
                  home?.shortName ?? 'Home',
                  fixture.teamHDifficulty,
                  isHome: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _difficultyRow(
                  context,
                  away?.shortName ?? 'Away',
                  fixture.teamADifficulty,
                  isHome: false,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _difficultyRow(
    BuildContext context,
    String teamName,
    int difficulty, {
    required bool isHome,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            teamName,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHome ? 'Home' : 'Away',
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          DifficultyBadge(difficulty: difficulty, size: 32),
          const SizedBox(height: 4),
          Text(
            getDifficultyLabel(difficulty),
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Models & Custom Pitch Painter ───────────────────────────────────────────

class _GoalEventData {
  final String scorerName;
  final int count;
  final String? assisterName;
  final bool isOwnGoal;

  const _GoalEventData({
    required this.scorerName,
    this.count = 1,
    this.assisterName,
    this.isOwnGoal = false,
  });

  String get label {
    if (isOwnGoal) return '$scorerName (OG)';
    if (count > 1) return '$scorerName (x$count)';
    return scorerName;
  }
}

class _LineupPlayerItem {
  final Player player;
  final int minsPlayed;
  final int points;
  int? subbedOffMin;
  String? subbedForPlayerName;

  _LineupPlayerItem({
    required this.player,
    required this.minsPlayed,
    required this.points,
  });
}

class _TeamLineupData {
  final List<_LineupPlayerItem> startingXI;
  final List<_LineupPlayerItem> substitutedIn;
  final List<_LineupPlayerItem> bench;

  const _TeamLineupData({
    required this.startingXI,
    required this.substitutedIn,
    required this.bench,
  });
}

class _StatMeta {
  final String label;
  final IconData icon;
  final Color color;
  final int? pointsEach;

  const _StatMeta({
    required this.label,
    required this.icon,
    required this.color,
    this.pointsEach,
  });
}

class _StatDisplayEntry {
  final FixtureStatEntry stat;
  final bool isHome;
  const _StatDisplayEntry(this.stat, {required this.isHome});
}

class _PitchFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grass stripes
    const stripe1 = Color(0xFF228B22);
    const stripe2 = Color(0xFF2E8B57);
    const nStripes = 8;
    final stripeH = h / nStripes;
    for (int i = 0; i < nStripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, w, stripeH),
        Paint()..color = i.isEven ? stripe1 : stripe2,
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Boundary
    canvas.drawRect(Rect.fromLTWH(8, 8, w - 16, h - 16), linePaint);
    // Halfway line
    canvas.drawLine(Offset(8, h / 2), Offset(w - 8, h / 2), linePaint);
    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), 34, linePaint);
    // Center dot
    canvas.drawCircle(Offset(w / 2, h / 2), 2.5, Paint()..color = Colors.white.withAlpha(180));

    // Penalty areas
    canvas.drawRect(Rect.fromLTWH((w - 110) / 2, 8, 110, 48), linePaint);
    canvas.drawRect(Rect.fromLTWH((w - 110) / 2, h - 56, 110, 48), linePaint);

    // Goal areas
    canvas.drawRect(Rect.fromLTWH((w - 56) / 2, 8, 56, 20), linePaint);
    canvas.drawRect(Rect.fromLTWH((w - 56) / 2, h - 28, 56, 20), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
