import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../models/fixture.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/fixture_card.dart';
import 'price_changes_screen.dart';
import 'captain_matrix_screen.dart';
import 'player_detail_screen.dart';
import 'gameweek_detail_screen.dart';
import 'fpl_team_screen.dart';
import 'top_performers_screen.dart';
import 'transfer_activity_screen.dart';
import 'fixtures_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: _buildAppBar(context, provider),
          body: provider.isLoading
              ? const _DashboardSkeleton()
              : provider.error != null && provider.players.isEmpty
              ? _buildError(context, provider)
              : RefreshIndicator(
                  color: AppColors.of(context).primary,
                  backgroundColor: AppColors.of(context).cardDark,
                  onRefresh: provider.refresh,
                  child: _DashboardContent(provider: provider),
                ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, FplProvider provider) {
    return AppBar(
      backgroundColor: AppColors.of(context).secondary,
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
              color: AppColors.of(context).primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.of(context).primary.withAlpha(80),
              ),
            ),
            child: Text(
              'GW${provider.currentGameweek!.id}',
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: AppColors.of(context).textSecondary,
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
            Icon(Icons.cloud_off, color: AppColors.of(context).error, size: 64),
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
                backgroundColor: AppColors.of(context).primary,
                foregroundColor: AppColors.of(context).secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => provider.loadAllData(forceRefresh: true),
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

class _DashboardContent extends StatefulWidget {
  final FplProvider provider;

  const _DashboardContent({required this.provider});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  Timer? _liveRefreshTimer;

  @override
  void initState() {
    super.initState();
    _startLiveTimer();
  }

  void _startLiveTimer() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final currentGw = widget.provider.currentGameweek;
      if (currentGw == null) return;
      final gwFixtures = widget.provider.getFixturesForGameweek(currentGw.id);
      final hasLive = gwFixtures.any((f) => f.isLive);
      if (hasLive) {
        widget.provider.updateFixturesForGameweek(currentGw.id);
      }
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  FplProvider get provider => widget.provider;

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
              const SizedBox(height: 10),
              _buildQuickToolsRow(context),
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
              Row(
                children: [
                  Expanded(
                    child: _buildSectionTitle(context, 'Top Performers'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TopPerformersScreen(),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTopPerformers(context),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSectionTitle(context, 'Transfer Activity'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransferActivityScreen(),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTransferSection(context),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(context, 'Upcoming Fixtures'),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FixturesScreen(),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
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
          border: Border.all(color: AppColors.of(context).divider, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.of(context).primary.withAlpha(22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.of(context).primary.withAlpha(80),
                ),
              ),
              child: Text(
                gw.name,
                style: TextStyle(
                  color: AppColors.of(context).primary,
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
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (gw.averageEntryScore != null)
                    Text(
                      'Avg ${gw.averageEntryScore} pts',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
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
                    style: TextStyle(
                      color: AppColors.of(context).primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'High Score',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.of(context).textSecondary,
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
                  AppColors.of(context).primary.withAlpha(20),
                  AppColors.of(context).accent.withAlpha(14),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.of(context).primary.withAlpha(60),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).primary.withAlpha(28),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.of(context).primary.withAlpha(70),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.manage_accounts_rounded,
                      color: AppColors.of(context).primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My FPL Team',
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track your official FPL team points',
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.of(context).primary,
                  size: 20,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 80.ms)
        .slideY(begin: 0.06, end: 0);
  }

  Widget _buildQuickToolsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickToolButton(
            context,
            title: 'Price Changes',
            subtitle: 'Predicted rises & falls',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF00FF87),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PriceChangesScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickToolButton(
            context,
            title: 'Captain Decider',
            subtitle: 'AI rating & top picks',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFFBBF24),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CaptainMatrixScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickToolButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
          valueColor: AppColors.of(context).primary,
          imageUrl: topScorer?.photoUrl,
          onTap: topScorer == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerDetailScreen(player: topScorer),
                  ),
                ),
        ).animate().fadeIn(delay: 100.ms),
        StatCard(
          title: 'Top Assists',
          value: topAssist?.webName ?? '-',
          subtitle: '${topAssist?.assists ?? 0} assists',
          icon: Icons.sports_soccer_rounded,
          valueColor: AppColors.of(context).accent,
          imageUrl: topAssist?.photoUrl,
          onTap: topAssist == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerDetailScreen(player: topAssist),
                  ),
                ),
        ).animate().fadeIn(delay: 200.ms),
        StatCard(
          title: 'Most Owned',
          value: topSelected?.webName ?? '-',
          subtitle: formatPercent(topSelected?.selectedByPercent),
          icon: Icons.people_rounded,
          valueColor: const Color(0xFFA78BFA),
          imageUrl: topSelected?.photoUrl,
          onTap: topSelected == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerDetailScreen(player: topSelected),
                  ),
                ),
        ).animate().fadeIn(delay: 300.ms),
        StatCard(
          title: 'Best Value',
          value: topValue?.webName ?? '-',
          subtitle: formatPrice(topValue?.nowCost ?? 0),
          icon: Icons.trending_up_rounded,
          valueColor: const Color(0xFF34D399),
          imageUrl: topValue?.photoUrl,
          onTap: topValue == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerDetailScreen(player: topValue),
                  ),
                ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildTopPerformers(BuildContext context) {
    final top = provider.getTopScorersByPoints(limit: 5);
    return Container(
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Player',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pts',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Form',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Price',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.of(context).divider),
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
                      color: AppColors.of(context).divider,
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
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.of(context).cardMedium,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: player.photoUrl,
                        fit: BoxFit.cover,
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rank badge
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? AppColors.of(context).primary
                            : AppColors.of(context).cardMedium,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: idx == 0
                                ? AppColors.of(context).secondary
                                : AppColors.of(context).textSecondary,
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
                            style: TextStyle(
                              color: AppColors.of(context).textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            team?.shortName ?? '',
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${player.totalPoints}',
                        style: TextStyle(
                          color: AppColors.of(context).primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatForm(player.form),
                        style: TextStyle(
                          color: AppColors.of(context).accent,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatPrice(player.nowCost),
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
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
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(
                  isIn ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                  color: isIn
                      ? AppColors.of(context).primary
                      : AppColors.of(context).error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Transfers $title',
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.of(context).divider),
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
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.of(context).cardMedium,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: p.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Icon(
                          Icons.person,
                          color: AppColors.of(context).textSecondary,
                          size: 14,
                        ),
                        errorWidget: (_, _, _) => Icon(
                          Icons.person,
                          color: AppColors.of(context).textSecondary,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.webName,
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
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
                        color: isIn
                            ? AppColors.of(context).primary
                            : AppColors.of(context).error,
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
    final gameweek = provider.currentGameweek;

    List<Fixture> fixturesToShow;
    if (gameweek != null) {
      final allGwFixtures = provider.fixtures
          .where((f) => f.event == gameweek.id)
          .toList();
      if (allGwFixtures.isNotEmpty && (!gameweek.finished || provider.getUpcomingFixtures().isEmpty)) {
        // Keep ALL fixtures for the current gameweek (finished, live, and upcoming)
        fixturesToShow = allGwFixtures;
      } else {
        fixturesToShow = provider.getUpcomingFixtures(limit: 10);
      }
    } else {
      fixturesToShow = provider.getUpcomingFixtures(limit: 10);
    }

    if (fixturesToShow.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.gradientCard(context: context),
        child: Center(
          child: Text(
            'No fixtures available',
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ),
      );
    }

    // Group fixtures by day
    final Map<String, List<Fixture>> groupedByDay = {};
    for (final f in fixturesToShow) {
      if (f.kickoffTime == null) continue;
      final dateStr = formatDateShort(f.kickoffTime!);
      groupedByDay.putIfAbsent(dateStr, () => []).add(f);
    }

    final children = <Widget>[];
    for (final entry in groupedByDay.entries) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0),
          child: Text(
            entry.key,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      children.addAll(
        entry.value.map(
          (fixture) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FixtureCard(
              fixture: fixture,
              provider: provider,
              compact: true,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
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
