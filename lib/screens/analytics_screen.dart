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

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
            backgroundColor: AppColors.secondary,
            title: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5A0), Color(0xFF00A87A)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.analytics,
                      color: Color(0xFF0C0720),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Analytics'),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Form Chart'),
                Tab(text: 'Value Chart'),
                Tab(text: 'Heat Map'),
                Tab(text: 'Radar'),
              ],
            ),
          ),
          body: provider.isLoading
              ? const LoadingWidget(height: 400)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _FormChartTab(provider: provider),
                    _ValueChartTab(provider: provider),
                    const _HeatMapTab(),
                    _RadarTab(provider: provider),
                  ],
                ),
        );
      },
    );
  }
}

// ── Tab 1: Form Chart ─────────────────────────────────────────────────────────

class _FormChartTab extends StatefulWidget {
  final FplProvider provider;
  const _FormChartTab({required this.provider});

  @override
  State<_FormChartTab> createState() => _FormChartTabState();
}

class _FormChartTabState extends State<_FormChartTab> {
  int _posFilter = 0; // 0 = all

  @override
  Widget build(BuildContext context) {
    final players = widget.provider.players.where((p) {
      return _posFilter == 0 || p.elementType == _posFilter;
    }).toList()..sort((a, b) => b.formValue.compareTo(a.formValue));

    final top = players.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.sectionTitle(context, 'Top Form Players'),
          const SizedBox(height: 10),
          _buildPositionFilter(),
          const SizedBox(height: 16),
          if (top.isEmpty)
            const Center(
              child: Text(
                'No data',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else ...[
            _buildFormBarChart(top),
            const SizedBox(height: 20),
            _buildFormList(context, top),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionFilter() {
    final labels = {0: 'All', 1: 'GK', 2: 'DEF', 3: 'MID', 4: 'FWD'};
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: labels.entries.map((e) {
          final isSelected = _posFilter == e.key;
          final color = e.key == 0
              ? AppColors.primary
              : PositionConstants.positionColors[e.key]!;
          return GestureDetector(
            onTap: () => setState(() => _posFilter = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(30) : AppColors.cardMedium,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormBarChart(List<Player> players) {
    final maxForm = players
        .map((p) => p.formValue)
        .fold(0.0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form (5-game rolling avg)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxForm * 1.2,
                barGroups: players.asMap().entries.map((e) {
                  final posColor = getPositionColor(e.value.elementType);
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.formValue,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [posColor.withAlpha(150), posColor],
                        ),
                        width: 22,
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
                        v.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
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
                        if (idx < 0 || idx >= players.length) {
                          return const SizedBox.shrink();
                        }
                        final lastName = players[idx].webName.split(' ').last;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            lastName.substring(0, lastName.length.clamp(0, 7)),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
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
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Position legend
          Wrap(
            spacing: 12,
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
                    PositionConstants.positionNames[e.key] ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormList(BuildContext context, List<Player> players) {
    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: players.asMap().entries.map((e) {
          final i = e.key;
          final player = e.value;
          final team = widget.provider.getTeamById(player.teamId);
          final posColor = getPositionColor(player.elementType);
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerDetailScreen(player: player),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: i < players.length - 1 ? 1 : 0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i == 0
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  _buildPlayerPhoto(player, posColor),
                  const SizedBox(width: 10),
                  Expanded(
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
                          '${team?.shortName ?? ''} · ${getPositionShort(player.elementType)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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
                        formatForm(player.form),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'form',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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

  Widget _buildPlayerPhoto(Player player, Color posColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardMedium,
        border: Border.all(color: posColor, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: player.photoUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            const Icon(Icons.person, color: AppColors.textSecondary, size: 18),
        errorWidget: (_, __, ___) =>
            const Icon(Icons.person, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

// ── Tab 2: Value Chart ────────────────────────────────────────────────────────

class _ValueChartTab extends StatefulWidget {
  final FplProvider provider;
  const _ValueChartTab({required this.provider});

  @override
  State<_ValueChartTab> createState() => _ValueChartTabState();
}

class _ValueChartTabState extends State<_ValueChartTab> {
  int _posFilter = 0;

  @override
  Widget build(BuildContext context) {
    final allPlayers = widget.provider.players.where((p) {
      return (_posFilter == 0 || p.elementType == _posFilter) &&
          p.totalPoints > 0;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.sectionTitle(context, 'Price vs Points'),
          const SizedBox(height: 10),
          _buildPositionFilter(),
          const SizedBox(height: 16),
          _buildBubbleChart(context, allPlayers),
          const SizedBox(height: 16),
          _buildBubbleLegend(),
        ],
      ),
    );
  }

  Widget _buildPositionFilter() {
    final labels = {0: 'All', 1: 'GK', 2: 'DEF', 3: 'MID', 4: 'FWD'};
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: labels.entries.map((e) {
          final isSelected = _posFilter == e.key;
          final color = e.key == 0
              ? AppColors.primary
              : PositionConstants.positionColors[e.key]!;
          return GestureDetector(
            onTap: () => setState(() {
              _posFilter = e.key;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(30) : AppColors.cardMedium,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBubbleChart(BuildContext context, List<Player> players) {
    if (players.isEmpty) {
      return Container(
        height: 300,
        decoration: AppTheme.gradientCard(),
        child: const Center(
          child: Text(
            'No data',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final maxSelected = players
        .map((p) => p.selectedPercent)
        .fold(0.0, (a, b) => a > b ? a : b);

    final spots = players.asMap().entries.map((e) {
      final p = e.value;
      final x = p.nowCost / 10.0;
      final y = p.totalPoints.toDouble();
      final size = maxSelected > 0
          ? ((p.selectedPercent / maxSelected) * 14).clamp(4.0, 14.0)
          : 6.0;
      final color =
          PositionConstants.positionColors[p.elementType] ?? AppColors.primary;
      return ScatterSpot(
        x,
        y,
        dotPainter: FlDotCirclePainter(
          radius: size,
          color: color.withAlpha(180),
          strokeWidth: 1,
          strokeColor: color,
        ),
      );
    }).toList();

    final maxX = players
        .map((p) => p.nowCost / 10.0)
        .fold(0.0, (a, b) => a > b ? a : b);
    final maxY = players
        .map((p) => p.totalPoints.toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Each dot = 1 player  ·  Size = Ownership %  ·  Grid = value map',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: spots,
                minX: 3.5,
                maxX: maxX + 1,
                minY: 0,
                maxY: maxY + 20,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 0.5),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Points',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Price (£m)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        '£${v.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                scatterTouchData: ScatterTouchData(
                  enabled: true,
                  touchTooltipData: ScatterTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cardDark,
                    getTooltipItems: (spot) {
                      final idx = spots.indexOf(spot);
                      if (idx < 0 || idx >= players.length) return null;
                      final p = players[idx];
                      return ScatterTooltipItem(
                        '${p.webName}\n${formatPrice(p.nowCost)}  ${p.totalPoints}pts',
                        textStyle: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: PositionConstants.positionColors.entries.map((e) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: e.value,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                PositionConstants.positionFullNames[e.key] ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Tab 3: Heat Map (fixture difficulty) ─────────────────────────────────────

class _HeatMapTab extends StatelessWidget {
  const _HeatMapTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final currentGwId = provider.currentGameweek?.id ?? 1;
        final nextGws = List.generate(
          8,
          (i) => currentGwId + i,
        ).where((gw) => gw <= 38).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegend(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Fixture Difficulty Heat Map (next 8 GWs)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _buildHeader(nextGws),
                      const SizedBox(height: 4),
                      ...provider.teams.map(
                        (team) => _buildTeamRow(team, nextGws, provider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardDark,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Difficulty: ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            ...DifficultyConstants.colors.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${e.key} - ${DifficultyConstants.labels[e.key]}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<int> gws) {
    return Row(
      children: [
        const SizedBox(
          width: 72,
          child: Text(
            'Team',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...gws.map(
          (gw) => SizedBox(
            width: 80,
            child: Text(
              'GW$gw',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRow(dynamic team, List<int> gws, FplProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              team.shortName as String,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...gws.map((gw) {
            final gwFixtures = provider.fixtures
                .where(
                  (f) =>
                      f.event == gw &&
                      (f.homeTeamId == team.id || f.awayTeamId == team.id),
                )
                .toList();

            if (gwFixtures.isEmpty) {
              return SizedBox(
                width: 80,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.cardMedium,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      '-',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              width: 80,
              child: Column(
                children: gwFixtures.map((f) {
                  final isHome = f.homeTeamId == team.id;
                  final difficulty = isHome
                      ? f.teamHDifficulty
                      : f.teamADifficulty;
                  final opponentId = isHome ? f.awayTeamId : f.homeTeamId;
                  final opponent = provider.getTeamById(opponentId);
                  final diffColor =
                      DifficultyConstants.colors[difficulty] ?? Colors.grey;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: diffColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: diffColor.withAlpha(153)),
                    ),
                    child: Center(
                      child: Text(
                        '${opponent?.shortName ?? '?'}(${isHome ? 'H' : 'A'})',
                        style: TextStyle(
                          color: diffColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Tab 4: Radar chart ────────────────────────────────────────────────────────

class _RadarTab extends StatefulWidget {
  final FplProvider provider;
  const _RadarTab({required this.provider});

  @override
  State<_RadarTab> createState() => _RadarTabState();
}

class _RadarTabState extends State<_RadarTab> {
  Player? _playerA;
  Player? _playerB;
  final _searchACtrl = TextEditingController();
  final _searchBCtrl = TextEditingController();
  String _queryA = '';
  String _queryB = '';

  @override
  void initState() {
    super.initState();
    // Default to top ICT player
    final sorted = List<Player>.from(widget.provider.players)
      ..sort((a, b) => b.ictValue.compareTo(a.ictValue));
    if (sorted.isNotEmpty) _playerA = sorted.first;
    if (sorted.length > 1) _playerB = sorted[1];
  }

  @override
  void dispose() {
    _searchACtrl.dispose();
    _searchBCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.sectionTitle(context, 'Player Radar Comparison'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSelector(
                  'Player A',
                  _playerA,
                  _searchACtrl,
                  _queryA,
                  (q) => setState(() => _queryA = q),
                  (p) => setState(() {
                    _playerA = p;
                    _queryA = '';
                    _searchACtrl.clear();
                  }),
                  () => setState(() {
                    _playerA = null;
                    _queryA = '';
                    _searchACtrl.clear();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardMedium,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSelector(
                  'Player B',
                  _playerB,
                  _searchBCtrl,
                  _queryB,
                  (q) => setState(() => _queryB = q),
                  (p) => setState(() {
                    _playerB = p;
                    _queryB = '';
                    _searchBCtrl.clear();
                  }),
                  () => setState(() {
                    _playerB = null;
                    _queryB = '';
                    _searchBCtrl.clear();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_playerA != null) _buildRadarCard(context, _playerA!, _playerB),
          const SizedBox(height: 16),
          if (_playerA != null) _buildStatsCompareTable(_playerA!, _playerB),
        ],
      ),
    );
  }

  Widget _buildSelector(
    String label,
    Player? selected,
    TextEditingController ctrl,
    String query,
    Function(String) onQuery,
    Function(Player) onSelect,
    VoidCallback onClear,
  ) {
    final results = query.isNotEmpty
        ? widget.provider.searchPlayers(query).take(5).toList()
        : <Player>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected != null)
          _buildSelectedCard(selected, onClear)
        else
          TextField(
            controller: ctrl,
            onChanged: onQuery,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
            ),
          ),
        if (results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: results
                  .map(
                    (p) => InkWell(
                      onTap: () => onSelect(p),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
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
                              formatPrice(p.nowCost),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedCard(Player player, VoidCallback onClear) {
    final posColor = getPositionColor(player.elementType);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: AppTheme.gradientCard(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardMedium,
              border: Border.all(color: posColor, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
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
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              player.webName,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarCard(BuildContext context, Player a, Player? b) {
    // Normalize stats to 0-1: ICT, Influence, Creativity, Threat, PPG, Form
    double maxIct = 200,
        maxInf = 200,
        maxCre = 200,
        maxThr = 200,
        maxPpg = 12,
        maxForm = 10;

    List<double> normalise(Player p) => [
      (p.ictValue / maxIct).clamp(0.0, 1.0),
      (p.influenceValue / maxInf).clamp(0.0, 1.0),
      (p.creativityValue / maxCre).clamp(0.0, 1.0),
      (p.threatValue / maxThr).clamp(0.0, 1.0),
      (p.ppgValue / maxPpg).clamp(0.0, 1.0),
      (p.formValue / maxForm).clamp(0.0, 1.0),
    ];

    final labelsText = [
      'ICT',
      'Influence',
      'Creativity',
      'Threat',
      'PPG',
      'Form',
    ];
    final valuesA = normalise(a);
    final valuesB = b != null ? normalise(b) : <double>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attribute Radar',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(AppColors.primary, a.webName),
              if (b != null) ...[
                const SizedBox(width: 16),
                _legendDot(AppColors.accent, b.webName),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withAlpha(50),
                    borderColor: AppColors.primary,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: valuesA
                        .map((v) => RadarEntry(value: v))
                        .toList(),
                  ),
                  if (b != null)
                    RadarDataSet(
                      fillColor: AppColors.accent.withAlpha(50),
                      borderColor: AppColors.accent,
                      borderWidth: 2,
                      entryRadius: 3,
                      dataEntries: valuesB
                          .map((v) => RadarEntry(value: v))
                          .toList(),
                    ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: AppColors.divider),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                getTitle: (index, angle) {
                  return RadarChartTitle(text: labelsText[index], angle: angle);
                },
                tickCount: 4,
                ticksTextStyle: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 0,
                ),
                tickBorderData: const BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ),
                gridBorderData: const BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCompareTable(Player a, Player? b) {
    final rows = [
      (
        'Total Points',
        '${a.totalPoints}',
        b != null ? '${b.totalPoints}' : '–',
      ),
      ('Form', formatForm(a.form), b != null ? formatForm(b.form) : '–'),
      (
        'ICT Index',
        a.ictValue.toStringAsFixed(1),
        b != null ? b.ictValue.toStringAsFixed(1) : '–',
      ),
      (
        'Influence',
        a.influenceValue.toStringAsFixed(1),
        b != null ? b.influenceValue.toStringAsFixed(1) : '–',
      ),
      (
        'Creativity',
        a.creativityValue.toStringAsFixed(1),
        b != null ? b.creativityValue.toStringAsFixed(1) : '–',
      ),
      (
        'Threat',
        a.threatValue.toStringAsFixed(1),
        b != null ? b.threatValue.toStringAsFixed(1) : '–',
      ),
      (
        'PPG',
        formatDouble(a.pointsPerGame),
        b != null ? formatDouble(b.pointsPerGame) : '–',
      ),
      (
        'Price',
        formatPrice(a.nowCost),
        b != null ? formatPrice(b.nowCost) : '–',
      ),
    ];

    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    a.webName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  'Stat',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Expanded(
                  child: Text(
                    b?.webName ?? '–',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...rows.map((r) {
            final numA =
                double.tryParse(r.$2.replaceAll(RegExp(r'[£%m]'), '')) ?? 0;
            final numB =
                double.tryParse(r.$3.replaceAll(RegExp(r'[£%m]'), '')) ?? 0;
            final aWins = b != null && numA > numB;
            final bWins = b != null && numB > numA;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.$2,
                      style: TextStyle(
                        color: aWins
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: aWins ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      r.$1,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$3,
                      style: TextStyle(
                        color: bWins ? AppColors.accent : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: bWins ? FontWeight.w700 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
