import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
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
import 'gameweek_detail_screen.dart';
import 'fixture_detail_screen.dart';
import 'fpl_team_screen.dart';

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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00E5A0), Color(0xFF00A87A)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'FPL',
                style: TextStyle(
                  color: Color(0xFF0C0720),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text('FPL Analytics'),
        ],
      ),
      actions: [
        if (provider.currentGameweek != null)
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(80)),
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
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.textSecondary,
          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: provider.loadAllData,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
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
        ? (List<Player>.from(
                provider.players,
              )..sort((a, b) => b.selectedPercent.compareTo(a.selectedPercent)))
              .first
        : null;
    final topValue = provider.players.isNotEmpty
        ? (List<Player>.from(provider.players)..sort(
                (a, b) => b.valueSeasonValue.compareTo(a.valueSeasonValue),
              ))
              .first
        : null;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildCurrentGwBanner(context),
              const SizedBox(height: 12),
              _buildMyFplTeamCard(context),
              const SizedBox(height: 16),
              _buildSparklines(context),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Highlights'),
              const SizedBox(height: 12),
              _buildStatsGrid(
                context,
                topScorer,
                topAssist,
                topSelected,
                topValue,
              ),
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
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameweekDetailScreen(gw: gw, provider: provider),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF160D36), Color(0xFF0D0622)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Text(
                gw.name,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gw.statusLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (gw.averageEntryScore != null)
                    Text(
                      'Avg ${gw.averageEntryScore} pts',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (gw.highestScore != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${gw.highestScore}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'High Score',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildMyFplTeamCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FplTeamScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withAlpha(20),
              AppColors.accent.withAlpha(14),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withAlpha(60), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.primary.withAlpha(70)),
              ),
              child: const Center(
                child: Icon(Icons.manage_accounts_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My FPL Team',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Track your official FPL team points',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.06, end: 0);
  }

  // ── Sparklines ────────────────────────────────────────────────────────────

  Widget _buildSparklines(BuildContext context) {
    final finishedGws = provider.gameweeks
        .where((gw) => gw.finished && gw.averageEntryScore != null)
        .toList();

    if (finishedGws.isEmpty) return const SizedBox.shrink();

    final avgScores = finishedGws
        .map((gw) => gw.averageEntryScore!.toDouble())
        .toList();
    final highScores = finishedGws
        .where((gw) => gw.highestScore != null)
        .map((gw) => gw.highestScore!.toDouble())
        .toList();
    final transfers = finishedGws
        .map((gw) => gw.transfersMade.toDouble())
        .toList();

    // Top form players — current PPG trend (top 5 players' PPG as a mini bar)
    final topByForm = provider.getTopScorersByForm(limit: 5);
    final formValues = topByForm.map((p) => p.formValue).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Season Trends'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSparkCard(
                context,
                'GW Avg Score',
                avgScores.isEmpty ? '–' : '${avgScores.last.toInt()} pts',
                avgScores,
                AppColors.primary,
                Icons.show_chart_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SeasonTrendScreenFactory.avgScore(finishedGws),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSparkCard(
                context,
                'GW High Score',
                highScores.isEmpty ? '–' : '${highScores.last.toInt()} pts',
                highScores,
                AppColors.warning,
                Icons.emoji_events_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SeasonTrendScreenFactory.highScore(finishedGws),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSparkCard(
                context,
                'Transfers / GW',
                transfers.isEmpty
                    ? '–'
                    : '${(transfers.last / 1000).toStringAsFixed(0)}k',
                transfers,
                AppColors.accent,
                Icons.swap_horiz_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SeasonTrendScreenFactory.transfers(finishedGws),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSparkCard(
                context,
                'Top Form (live)',
                formValues.isEmpty ? '–' : formValues.first.toStringAsFixed(1),
                formValues,
                const Color(0xFF34D399),
                Icons.trending_up_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormLeadersScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSparkCard(
    BuildContext context,
    String title,
    String value,
    List<double> data,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final hasData = data.length >= 2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.gradientCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (hasData)
              SizedBox(height: 40, child: _buildSparkline(data, color))
            else
              const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkline(List<double> data, Color color) {
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs();
    final effectiveRange = range < 0.001 ? 1.0 : range;

    final spots = data.asMap().entries.map((e) {
      final norm = (e.value - minVal) / effectiveRange;
      return FlSpot(e.key.toDouble(), norm);
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withAlpha(40)),
          ),
        ],
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: -0.05,
        maxY: 1.05,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return AppTheme.sectionTitle(context, title);
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
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: 'Top Scorer',
          value: topScorer?.webName ?? '-',
          subtitle: '${topScorer?.totalPoints ?? 0} pts',
          icon: Icons.star_rounded,
          valueColor: AppColors.primary,
          imageUrl: topScorer?.photoUrl,
        ).animate().fadeIn(delay: 100.ms),
        StatCard(
          title: 'Top Assists',
          value: topAssist?.webName ?? '-',
          subtitle: '${topAssist?.assists ?? 0} assists',
          icon: Icons.sports_soccer_rounded,
          valueColor: AppColors.accent,
          imageUrl: topAssist?.photoUrl,
        ).animate().fadeIn(delay: 200.ms),
        StatCard(
          title: 'Most Owned',
          value: topSelected?.webName ?? '-',
          subtitle: formatPercent(topSelected?.selectedByPercent),
          icon: Icons.people_rounded,
          valueColor: const Color(0xFFA78BFA),
          imageUrl: topSelected?.photoUrl,
        ).animate().fadeIn(delay: 300.ms),
        StatCard(
          title: 'Best Value',
          value: topValue?.webName ?? '-',
          subtitle: formatPrice(topValue?.nowCost ?? 0),
          icon: Icons.trending_up_rounded,
          valueColor: const Color(0xFF34D399),
          imageUrl: topValue?.photoUrl,
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
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Player',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pts',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Form',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Price',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...top.asMap().entries.map((entry) {
            final idx = entry.key;
            final player = entry.value;
            final team = provider.getTeamById(player.teamId);
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerDetailScreen(player: player),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.divider,
                      width: idx < top.length - 1 ? 1 : 0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Player photo
                    Container(
                      width: 36,
                      height: 36,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardMedium,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: player.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rank badge
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? AppColors.primary
                            : AppColors.cardMedium,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: idx == 0
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.webName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            team?.shortName ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${player.totalPoints}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatForm(player.form),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatPrice(player.nowCost),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
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
        Expanded(child: _buildTransferList(context, 'In', transfersIn, true)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTransferList(context, 'Out', transfersOut, false),
        ),
      ],
    );
  }

  Widget _buildTransferList(
    BuildContext context,
    String title,
    List<Player> players,
    bool isIn,
  ) {
    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(
                  isIn ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                  color: isIn ? AppColors.primary : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Transfers $title',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...players.map((p) {
            final count = isIn ? p.transfersInEvent : p.transfersOutEvent;
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerDetailScreen(player: p),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardMedium,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: p.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.webName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
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
          child: Text(
            'No upcoming fixtures',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: upcoming
          .map((fixture) => _buildFixtureRow(context, fixture))
          .toList(),
    );
  }

  Widget _buildFixtureRow(BuildContext context, Fixture fixture) {
    final home = provider.getTeamById(fixture.homeTeamId);
    final away = provider.getTeamById(fixture.awayTeamId);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FixtureDetailScreen(
            fixture: fixture,
            homeTeam: home,
            awayTeam: away,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.gradientCard(),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      home?.shortName ?? '?',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (home != null)
                    CachedNetworkImage(
                      imageUrl: home.badgeUrl,
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                      placeholder: (_, __) =>
                          const SizedBox(width: 26, height: 26),
                      errorWidget: (_, __, ___) =>
                          const SizedBox(width: 26, height: 26),
                    ),
                ],
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    )
                  : Text(
                      formatDateShort(fixture.kickoffTime),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  if (away != null)
                    CachedNetworkImage(
                      imageUrl: away.badgeUrl,
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                      placeholder: (_, __) =>
                          const SizedBox(width: 26, height: 26),
                      errorWidget: (_, __, ___) =>
                          const SizedBox(width: 26, height: 26),
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      away?.shortName ?? '?',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
