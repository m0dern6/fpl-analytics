import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Stats Leaders'),
            backgroundColor: AppColors.secondary,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Goals'),
                Tab(text: 'Assists'),
                Tab(text: 'Clean Sheets'),
                Tab(text: 'Bonus'),
                Tab(text: 'ICT'),
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
                      color: AppColors.primary,
                      label: 'Goals',
                    ),
                    _LeadersList(
                      players: provider.getTopScorersByAssists(limit: 10),
                      provider: provider,
                      valueGetter: (p) => p.assists.toDouble(),
                      valueFormatter: (v) => v.toInt().toString(),
                      color: AppColors.accent,
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
                      color: AppColors.warning,
                      label: 'Bonus Points',
                    ),
                    _LeadersList(
                      players: provider.getTopScorersByICT(limit: 10),
                      provider: provider,
                      valueGetter: (p) => p.ictValue,
                      valueFormatter: (v) => v.toStringAsFixed(1),
                      color: const Color(0xFFB388FF),
                      label: 'ICT Index',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

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
      return const Center(child: Text('No data', style: TextStyle(color: AppColors.textSecondary)));
    }

    final maxVal = players.map(valueGetter).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBarChart(maxVal),
          const SizedBox(height: 20),
          _buildLeadersList(context),
        ],
      ),
    );
  }

  Widget _buildBarChart(double maxVal) {
    if (maxVal == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
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
                    valueFormatter(v),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= players.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        players[idx].webName.split(' ').last.substring(0, players[idx].webName.split(' ').last.length.clamp(0, 6)),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 8),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadersList(BuildContext context) {
    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: players.asMap().entries.map((entry) {
          final i = entry.key;
          final player = entry.value;
          final team = provider.getTeamById(player.teamId);
          final val = valueGetter(player);

          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider, width: i < players.length - 1 ? 1 : 0)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i == 0 ? color : AppColors.textSecondary,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: i == 0 ? color : color.withAlpha(102),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.webName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(
                          '${team?.shortName ?? ''} · ${getPositionShort(player.elementType)} · ${formatPrice(player.nowCost)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        valueFormatter(val),
                        style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
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
