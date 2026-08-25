import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import 'player_detail_screen.dart';

class StatsLeadersScreen extends StatefulWidget {
  const StatsLeadersScreen({super.key});

  @override
  State<StatsLeadersScreen> createState() => _StatsLeadersScreenState();
}

class _StatsLeadersScreenState extends State<StatsLeadersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Stats Leaders'),
            backgroundColor: AppColors.of(context).secondary,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Goals'),
                Tab(text: 'Assists'),
                Tab(text: 'Clean Sheets'),
                Tab(text: 'Bonus'),
                Tab(text: 'By Position'),
              ],
            ),
          ),
          body: provider.isLoading
              ? const LoadingListWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _LeadersList(
                      players: provider.getTopScorersByGoals(limit: 10),
                      provider: provider,
                      valueGetter: (p) => p.goals.toDouble(),
                      valueFormatter: (v) => v.toInt().toString(),
                      color: AppColors.of(context).primary,
                      label: 'Goals',
                    ),
                    _LeadersList(
                      players: provider.getTopScorersByAssists(limit: 10),
                      provider: provider,
                      valueGetter: (p) => p.assists.toDouble(),
                      valueFormatter: (v) => v.toInt().toString(),
                      color: AppColors.of(context).accent,
                      label: 'Assists',
                    ),
                    _LeadersList(
                      players: provider.getTopScorersByCleanSheets(limit: 10),
                      provider: provider,
                      valueGetter: (p) => p.cleanSheets.toDouble(),
                      valueFormatter: (v) => v.toInt().toString(),
                      color: const Color(0xFF69F0AE),
                      label: 'Clean Sheets',
                    ),
                    _LeadersList(
                      players: provider.getTopBonusPlayers(limit: 10),
                      provider: provider,
                      valueGetter: (p) => p.bonus.toDouble(),
                      valueFormatter: (v) => v.toInt().toString(),
                      color: AppColors.of(context).warning,
                      label: 'Bonus Points',
                    ),
                    _BubbleTab(provider: provider),
                  ],
                ),
        );
      },
    );
  }
}

// ── Position Chart Tab ────────────────────────────────────────────────────────

class _BubbleTab extends StatefulWidget {
  final FplProvider provider;
  const _BubbleTab({required this.provider});

  @override
  State<_BubbleTab> createState() => _BubbleTabState();
}

class _BubbleTabState extends State<_BubbleTab> {
  int _posFilter = 0;

  @override
  Widget build(BuildContext context) {
    final players = widget.provider.players.where((p) {
      return _posFilter == 0 || p.elementType == _posFilter;
    }).toList()..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    final topPlayers = players.take(8).toList();
    final maxPoints = topPlayers.isEmpty
        ? 1.0
        : topPlayers
              .map((p) => p.totalPoints.toDouble())
              .reduce((a, b) => a > b ? a : b);

    final labels = {0: 'All', 1: 'GK', 2: 'DEF', 3: 'MID', 4: 'FWD'};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.sectionTitle(context, 'Top Scorers by Position'),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: labels.entries.map((e) {
                final isSel = _posFilter == e.key;
                final col = e.key == 0
                    ? AppColors.of(context).primary
                    : PositionConstants.positionColors[e.key]!;
                return GestureDetector(
                  onTap: () => setState(() => _posFilter = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSel
                          ? col.withAlpha(30)
                          : AppColors.of(context).cardMedium,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? col : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isSel
                            ? col
                            : AppColors.of(context).textSecondary,
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.gradientCard(context: context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bar height = total points  ·  Colour = position',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxPoints * 1.2,
                      barGroups: topPlayers.asMap().entries.map((entry) {
                        final player = entry.value;
                        final color =
                            PositionConstants.positionColors[player
                                .elementType] ??
                            AppColors.of(context).primary;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: player.totalPoints.toDouble(),
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [color.withAlpha(153), color],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: TextStyle(
                                color: AppColors.of(context).textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= topPlayers.length) {
                                return const SizedBox.shrink();
                              }
                              final shortName = topPlayers[idx].webName
                                  .split(' ')
                                  .last;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  shortName.length > 6
                                      ? shortName.substring(0, 6)
                                      : shortName,
                                  style: TextStyle(
                                    color: AppColors.of(context).textSecondary,
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.of(context).divider,
                          strokeWidth: 0.5,
                        ),
                        getDrawingVerticalLine: (_) => FlLine(
                          color: AppColors.of(context).divider,
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: PositionConstants.positionColors.entries.map((e) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: e.value,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          PositionConstants.positionFullNames[e.key] ?? '',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leaders List ──────────────────────────────────────────────────────────────

class _LeadersList extends StatelessWidget {
  final List<Player> players;
  final FplProvider provider;
  final double Function(Player) valueGetter;
  final String Function(double) valueFormatter;
  final Color color;
  final String label;

  const _LeadersList({
    required this.players,
    required this.provider,
    required this.valueGetter,
    required this.valueFormatter,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    final maxVal = players.map(valueGetter).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBarChart(context, maxVal),
          const SizedBox(height: 20),
          _buildLeadersList(context),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, double maxVal) {
    if (maxVal == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.2,
            barGroups: players.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: valueGetter(entry.value),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [color.withAlpha(153), color],
                    ),
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
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
                    valueFormatter(v),
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= players.length)
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        players[idx].webName
                            .split(' ')
                            .last
                            .substring(
                              0,
                              players[idx].webName
                                  .split(' ')
                                  .last
                                  .length
                                  .clamp(0, 6),
                            ),
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 8,
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.of(context).divider,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadersList(BuildContext context) {
    return Container(
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        children: players.asMap().entries.map((entry) {
          final i = entry.key;
          final player = entry.value;
          final team = provider.getTeamById(player.teamId);
          final val = valueGetter(player);
          final posColor = getPositionColor(player.elementType);

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerDetailScreen(player: player),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.of(context).divider,
                    width: i < players.length - 1 ? 1 : 0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i == 0
                            ? color
                            : AppColors.of(context).textSecondary,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Player photo
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.of(context).cardMedium,
                      border: Border.all(color: posColor, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: player.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 18,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.webName,
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${team?.shortName ?? ''} · ${getPositionShort(player.elementType)} · ${formatPrice(player.nowCost)}',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        valueFormatter(val),
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
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
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
