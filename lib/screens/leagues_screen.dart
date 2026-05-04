import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fpl_provider.dart';
import '../providers/fpl_entry_provider.dart';
import '../models/entry.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import 'league_detail_screen.dart';
import 'onboarding_screen.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FplProvider, FplEntryProvider>(
      builder: (context, fplProvider, entryProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            backgroundColor: AppColors.of(context).secondary,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5A0), Color(0xFF00A87A)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFF0C0720),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Leagues'),
              ],
            ),
            bottom: entryProvider.hasEntry
                ? TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Classic'),
                      Tab(text: 'H2H'),
                    ],
                  )
                : null,
          ),
          body: !entryProvider.hasEntry
              ? _NoEntryPrompt(
                  onLink: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _ClassicLeaguesList(entryProvider: entryProvider),
                    _H2HLeaguesList(entryProvider: entryProvider),
                  ],
                ),
        );
      },
    );
  }
}

// ── Classic Leagues ────────────────────────────────────────────────────────────

class _ClassicLeaguesList extends StatelessWidget {
  final FplEntryProvider entryProvider;

  const _ClassicLeaguesList({required this.entryProvider});

  @override
  Widget build(BuildContext context) {
    final leagues = entryProvider.entry?.leagues
            .where((l) => l.isClassic)
            .toList() ??
        [];

    if (entryProvider.isLoading) {
      return const LoadingWidget(height: 300);
    }

    if (leagues.isEmpty) {
      return _EmptyLeagues(
        message: 'No classic leagues found for your team.',
      );
    }

    return RefreshIndicator(
      color: AppColors.of(context).primary,
      backgroundColor: AppColors.of(context).cardDark,
      onRefresh: entryProvider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          return _LeagueCard(
            league: leagues[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LeagueDetailScreen(leagueId: leagues[index].id),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── H2H Leagues ────────────────────────────────────────────────────────────────

class _H2HLeaguesList extends StatelessWidget {
  final FplEntryProvider entryProvider;

  const _H2HLeaguesList({required this.entryProvider});

  @override
  Widget build(BuildContext context) {
    final leagues = entryProvider.entry?.leagues
            .where((l) => l.isH2H)
            .toList() ??
        [];

    if (entryProvider.isLoading) {
      return const LoadingWidget(height: 300);
    }

    if (leagues.isEmpty) {
      return _EmptyLeagues(
        message: "You're not in any H2H leagues.",
      );
    }

    return RefreshIndicator(
      color: AppColors.of(context).primary,
      backgroundColor: AppColors.of(context).cardDark,
      onRefresh: entryProvider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          return _LeagueCard(
            league: leagues[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LeagueDetailScreen(
                  leagueId: leagues[index].id,
                  isH2H: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────────

class _LeagueCard extends StatelessWidget {
  final FplLeagueMembership league;
  final VoidCallback onTap;

  const _LeagueCard({required this.league, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isPublic = league.isPublic;
    final rankChange = league.entryLastRank - league.entryRank;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPublic
                    ? colors.accent.withAlpha(20)
                    : colors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPublic
                      ? colors.accent.withAlpha(60)
                      : colors.primary.withAlpha(60),
                ),
              ),
              child: Icon(
                isPublic ? Icons.public_rounded : Icons.lock_rounded,
                color: isPublic ? colors.accent : colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    league.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Rank: ${formatNumber(league.entryRank)}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (league.entryLastRank > 0 && rankChange != 0) ...[
                        const SizedBox(width: 6),
                        Icon(
                          rankChange > 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: rankChange > 0 ? colors.primary : colors.error,
                          size: 12,
                        ),
                        Text(
                          rankChange.abs().toString(),
                          style: TextStyle(
                            color: rankChange > 0 ? colors.primary : colors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLeagues extends StatelessWidget {
  final String message;

  const _EmptyLeagues({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: colors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoEntryPrompt extends StatelessWidget {
  final VoidCallback onLink;

  const _NoEntryPrompt({required this.onLink});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, color: colors.primary, size: 64),
            const SizedBox(height: 20),
            Text(
              'Your Leagues',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Link your FPL team to see your leagues, standings, and rival comparisons.',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onLink,
              icon: const Icon(Icons.link_rounded),
              label: const Text(
                'Link Team',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
