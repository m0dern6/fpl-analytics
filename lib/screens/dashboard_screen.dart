import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../models/fixture.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/difficulty_badge.dart';
import 'player_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, provider),
          body: provider.isLoading
              ? const _DashboardSkeleton()
              : provider.error != null && provider.players.isEmpty
                  ? _buildError(context, provider)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.cardDark,
                      onRefresh: provider.refresh,
                      child: _DashboardContent(provider: provider),
                    ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, FplProvider provider) {
    return AppBar(
      backgroundColor: AppColors.secondary,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'FPL',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'FPL Analytics',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        if (provider.currentGameweek != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(102)),
            ),
            child: Text(
              'GW${provider.currentGameweek!.id}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          onPressed: provider.refresh,
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, FplProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: provider.loadAllData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final FplProvider provider;

  const _DashboardContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final topScorer = provider.getTopScorersByPoints(limit: 1).firstOrNull;
    final topAssist = provider.getTopScorersByAssists(limit: 1).firstOrNull;
    final topSelected = provider.players.isNotEmpty
        ? (List<Player>.from(provider.players)
              ..sort((a, b) => b.selectedPercent.compareTo(a.selectedPercent)))
            .first
        : null;
    final topValue = provider.players.isNotEmpty
        ? (List<Player>.from(provider.players)
              ..sort((a, b) => b.valueSeasonValue.compareTo(a.valueSeasonValue)))
            .first
        : null;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildCurrentGwBanner(context),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Highlights'),
              const SizedBox(height: 12),
              _buildStatsGrid(context, topScorer, topAssist, topSelected, topValue),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Top Performers'),
              const SizedBox(height: 12),
              _buildTopPerformers(context),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Transfer Activity'),
              const SizedBox(height: 12),
              _buildTransferSection(context),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Upcoming Fixtures'),
              const SizedBox(height: 12),
              _buildUpcomingFixtures(context),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentGwBanner(BuildContext context) {
    final gw = provider.currentGameweek;
    if (gw == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.purpleGradient(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gw.name,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${gw.statusLabel}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (gw.averageEntryScore != null)
                  Text(
                    'Avg Score: ${gw.averageEntryScore} pts',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (gw.highestScore != null)
                Text(
                  '${gw.highestScore}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (gw.highestScore != null)
                const Text(
                  'Highest Score',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    Player? topScorer,
    Player? topAssist,
    Player? topSelected,
    Player? topValue,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: 'Top Scorer',
          value: topScorer?.webName ?? '-',
          subtitle: '${topScorer?.totalPoints ?? 0} pts',
          icon: Icons.star,
          gradientColors: const [Color(0xFF1a3a5c), Color(0xFF0d2137)],
          valueColor: AppColors.primary,
        ).animate().fadeIn(delay: 100.ms),
        StatCard(
          title: 'Top Assists',
          value: topAssist?.webName ?? '-',
          subtitle: '${topAssist?.assists ?? 0} assists',
          icon: Icons.sports_soccer,
          gradientColors: const [Color(0xFF1a2a4c), Color(0xFF0d1a37)],
          valueColor: AppColors.accent,
        ).animate().fadeIn(delay: 200.ms),
        StatCard(
          title: 'Most Owned',
          value: topSelected?.webName ?? '-',
          subtitle: formatPercent(topSelected?.selectedByPercent),
          icon: Icons.people,
          gradientColors: const [Color(0xFF2a1a4c), Color(0xFF1a0d37)],
          valueColor: const Color(0xFFB388FF),
        ).animate().fadeIn(delay: 300.ms),
        StatCard(
          title: 'Best Value',
          value: topValue?.webName ?? '-',
          subtitle: formatPrice(topValue?.nowCost ?? 0),
          icon: Icons.trending_up,
          gradientColors: const [Color(0xFF1a3a2a), Color(0xFF0d2a1a)],
          valueColor: const Color(0xFF69F0AE),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildTopPerformers(BuildContext context) {
    final top = provider.getTopScorersByPoints(limit: 5);
    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Player', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                const Expanded(child: Text('Pts', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                const Expanded(child: Text('Form', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                const Expanded(child: Text('Price', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...top.asMap().entries.map((entry) {
            final idx = entry.key;
            final player = entry.value;
            final team = provider.getTeamById(player.teamId);
            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider, width: idx < top.length - 1 ? 1 : 0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: idx == 0 ? AppColors.primary : AppColors.cardMedium,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: idx == 0 ? AppColors.secondary : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.webName,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            team?.shortName ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${player.totalPoints}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatForm(player.form),
                        style: const TextStyle(color: AppColors.accent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatPrice(player.nowCost),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransferSection(BuildContext context) {
    final transfersIn = provider.getTopTransfersIn(limit: 5);
    final transfersOut = provider.getTopTransfersOut(limit: 5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTransferList(context, 'In', transfersIn, true),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTransferList(context, 'Out', transfersOut, false),
        ),
      ],
    );
  }

  Widget _buildTransferList(BuildContext context, String title, List<Player> players, bool isIn) {
    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(isIn ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                    color: isIn ? AppColors.primary : AppColors.error, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Transfers $title',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...players.map((p) {
            final count = isIn ? p.transfersInEvent : p.transfersOutEvent;
            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: p))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.webName,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      count >= 1000
                          ? '${(count / 1000).toStringAsFixed(1)}k'
                          : '$count',
                      style: TextStyle(
                        color: isIn ? AppColors.primary : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUpcomingFixtures(BuildContext context) {
    final upcoming = provider.getUpcomingFixtures(limit: 6);
    if (upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.gradientCard(),
        child: const Center(
          child: Text('No upcoming fixtures', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      children: upcoming.map((fixture) => _buildFixtureRow(context, fixture)).toList(),
    );
  }

  Widget _buildFixtureRow(BuildContext context, Fixture fixture) {
    final home = provider.getTeamById(fixture.homeTeamId);
    final away = provider.getTeamById(fixture.awayTeamId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.gradientCard(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              home?.shortName ?? '?',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardMedium,
              borderRadius: BorderRadius.circular(8),
            ),
            child: fixture.hasResult
                ? Text(
                    '${fixture.homeTeamScore} - ${fixture.awayTeamScore}',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                  )
                : Text(
                    formatDateShort(fixture.kickoffTime),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              away?.shortName ?? '?',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            children: [
              DifficultyBadge(difficulty: fixture.teamHDifficulty, size: 22),
              const SizedBox(width: 2),
              DifficultyBadge(difficulty: fixture.teamADifficulty, size: 22),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const LoadingWidget(height: 80),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (i) => const LoadingCardWidget()),
        ),
        const SizedBox(height: 20),
        const LoadingWidget(height: 220),
        const SizedBox(height: 20),
        const LoadingWidget(height: 160),
      ],
    );
  }
}
