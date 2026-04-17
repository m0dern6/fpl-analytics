import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/player_history.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/difficulty_badge.dart';

class PlayerDetailScreen extends StatefulWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FplProvider>().loadPlayerSummary(widget.player.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final team = context.read<FplProvider>().getTeamById(widget.player.teamId);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(team),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'History'),
                Tab(text: 'Fixtures'),
              ],
            ),
          ),
        ],
        body: Consumer<FplProvider>(
          builder: (ctx, provider, _) {
            final summary = provider.getPlayerSummary(widget.player.id);
            return TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(player: widget.player, team: team, summary: summary),
                _HistoryTab(player: widget.player, summary: summary),
                _FixturesTab(player: widget.player, summary: summary, provider: provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Team? team) {
    final pos = getPositionShort(widget.player.elementType);
    final posColor = getPositionColor(widget.player.elementType);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, Color(0xFF5a0060)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 8),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(77)),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: widget.player.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Icon(Icons.person, color: AppColors.textSecondary, size: 48),
                  errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textSecondary, size: 48),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.player.webName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${widget.player.firstName} ${widget.player.secondName}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: posColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: posColor),
                          ),
                          child: Text(pos, style: TextStyle(color: posColor, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Text(team?.name ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _headerStat(formatPrice(widget.player.nowCost), 'Price'),
                        const SizedBox(width: 16),
                        _headerStat('${widget.player.totalPoints}', 'Pts'),
                        const SizedBox(width: 16),
                        _headerStat(formatForm(widget.player.form), 'Form'),
                      ],
                    ),
                    if (widget.player.news.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.warning, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.player.news,
                                style: const TextStyle(color: AppColors.warning, fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Player player;
  final Team? team;
  final PlayerSummary? summary;

  const _OverviewTab({required this.player, this.team, this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 20),
          _buildIctSection(),
          const SizedBox(height: 20),
          _buildTransferSection(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem('Total Points', '${player.totalPoints}', Icons.star, AppColors.primary),
      _StatItem('Form', formatForm(player.form), Icons.trending_up, AppColors.accent),
      _StatItem('Price', formatPrice(player.nowCost), Icons.attach_money, const Color(0xFF69F0AE)),
      _StatItem('Selected %', formatPercent(player.selectedByPercent), Icons.people, const Color(0xFFB388FF)),
      _StatItem('Goals', '${player.goals}', Icons.sports_soccer, AppColors.primary),
      _StatItem('Assists', '${player.assists}', Icons.sports, AppColors.accent),
      _StatItem('Clean Sheets', '${player.cleanSheets}', Icons.shield, const Color(0xFF69F0AE)),
      _StatItem('Bonus Pts', '${player.bonus}', Icons.add_circle, AppColors.warning),
      _StatItem('Minutes', '${player.minutes}', Icons.timer, AppColors.textSecondary),
      _StatItem('Goals Conc.', '${player.goalsConceded}', Icons.sports_soccer_outlined, AppColors.error),
      _StatItem('Yellow Cards', '${player.yellowCards}', Icons.square, AppColors.warning),
      _StatItem('Saves', '${player.saves}', Icons.back_hand, AppColors.accent),
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stats
          .map((s) => Container(
                padding: const EdgeInsets.all(10),
                decoration: AppTheme.gradientCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(s.icon, color: s.color, size: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.value, style: TextStyle(color: s.color, fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(s.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildIctSection() {
    final ict = double.tryParse(player.ictIndex) ?? 0;
    final influence = double.tryParse(player.influence) ?? 0;
    final creativity = double.tryParse(player.creativity) ?? 0;
    final threat = double.tryParse(player.threat) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ICT Index', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _ictBar('ICT Index', ict, 200, AppColors.primary),
          const SizedBox(height: 10),
          _ictBar('Influence', influence, 200, AppColors.accent),
          const SizedBox(height: 10),
          _ictBar('Creativity', creativity, 200, const Color(0xFFB388FF)),
          const SizedBox(height: 10),
          _ictBar('Threat', threat, 200, AppColors.warning),
        ],
      ),
    );
  }

  Widget _ictBar(String label, double value, double maxVal, Color color) {
    final pct = (value / maxVal).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.cardMedium,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTransferSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transfer Activity', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _transferStat(
                  'In (Season)',
                  _formatCount(player.transfersIn),
                  Icons.arrow_upward,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _transferStat(
                  'Out (Season)',
                  _formatCount(player.transfersOut),
                  Icons.arrow_downward,
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _transferStat(
                  'In (GW)',
                  _formatCount(player.transfersInEvent),
                  Icons.arrow_upward,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _transferStat(
                  'Out (GW)',
                  _formatCount(player.transfersOutEvent),
                  Icons.arrow_downward,
                  AppColors.error,
                ),
              ),
            ],
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

  Widget _transferStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _HistoryTab extends StatelessWidget {
  final Player player;
  final PlayerSummary? summary;

  const _HistoryTab({required this.player, this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (summary!.history.isEmpty) {
      return const Center(child: Text('No history available', style: TextStyle(color: AppColors.textSecondary)));
    }

    final last10 = summary!.history.reversed.take(10).toList().reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPointsChart(last10),
          const SizedBox(height: 20),
          _buildHistoryTable(),
        ],
      ),
    );
  }

  Widget _buildPointsChart(List<PlayerHistory> history) {
    if (history.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Points History (Last 10 GW)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (history.map((h) => h.totalPoints).reduce((a, b) => a > b ? a : b) + 4).toDouble(),
                barGroups: history.asMap().entries.map((entry) {
                  final pts = entry.value.totalPoints.toDouble();
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: pts,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.primary.withAlpha(153),
                            AppColors.primary,
                          ],
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'GW${history[v.toInt()].round}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 36, child: Text('GW', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Opp', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                SizedBox(width: 32, child: Text('Min', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                SizedBox(width: 28, child: Text('G', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                SizedBox(width: 28, child: Text('A', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                SizedBox(width: 28, child: Text('Pts', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...summary!.history.reversed.take(20).map((h) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text('${h.round}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(
                        '${h.wasHome ? 'vs' : '@'} ${h.opponentTeam}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text('${h.minutes}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text('${h.goalsScored}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12), textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text('${h.assists}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12), textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${h.totalPoints}',
                        style: TextStyle(
                          color: h.totalPoints >= 8 ? AppColors.primary : h.totalPoints >= 6 ? AppColors.accent : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _FixturesTab extends StatelessWidget {
  final Player player;
  final PlayerSummary? summary;
  final FplProvider provider;

  const _FixturesTab({required this.player, this.summary, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (summary!.fixtures.isEmpty) {
      return const Center(child: Text('No upcoming fixtures', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: summary!.fixtures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final fixture = summary!.fixtures[i];
        final isHome = fixture.isHome;
        final opponentId = isHome ? fixture.teamA : fixture.teamH;
        final opponent = provider.getTeamById(opponentId);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.gradientCard(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardMedium,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('GW${fixture.event}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      opponent?.shortName ?? '?',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardMedium,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isHome ? 'H' : 'A',
                        style: TextStyle(
                          color: isHome ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatDateShort(fixture.kickoffTime),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 12),
              DifficultyBadge(difficulty: fixture.difficulty),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
      },
    );
  }
}
