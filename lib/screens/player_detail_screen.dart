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
  final _scrollControllers = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final idx = _tabController.index;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final controller = _scrollControllers[idx];
          if (controller.hasClients) {
            controller.jumpTo(0);
          }
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FplProvider>().loadPlayerSummary(widget.player.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final team = context.read<FplProvider>().getTeamById(widget.player.teamId);
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.of(context).secondary,
            flexibleSpace: FlexibleSpaceBar(background: _buildHeroHeader(team)),
            bottom: TabBar(
              controller: _tabController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              labelPadding: const EdgeInsets.symmetric(vertical: 12),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              indicatorColor: AppColors.of(context).primary,
              dividerColor: Colors.white10,
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
                _OverviewTab(
                  player: widget.player,
                  team: team,
                  summary: summary,
                  scrollController: _scrollControllers[0],
                ),
                _HistoryTab(
                  player: widget.player,
                  summary: summary,
                  provider: provider,
                  scrollController: _scrollControllers[1],
                ),
                _FixturesTab(
                  player: widget.player,
                  summary: summary,
                  provider: provider,
                  scrollController: _scrollControllers[2],
                ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.of(context).secondary, Color(0xFF5a0060)],
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
                  color: AppColors.of(context).cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.of(context).primary.withAlpha(77),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: widget.player.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Icon(
                    Icons.person,
                    color: AppColors.of(context).textSecondary,
                    size: 48,
                  ),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.person,
                    color: AppColors.of(context).textSecondary,
                    size: 48,
                  ),
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
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${widget.player.firstName} ${widget.player.secondName}',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: posColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: posColor),
                          ),
                          child: Text(
                            pos,
                            style: TextStyle(
                              color: posColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          team?.name ?? '',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _headerStat(
                          formatPrice(widget.player.nowCost),
                          'Price',
                        ),
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
                            Icon(
                              Icons.info_outline,
                              color: AppColors.of(context).warning,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.player.news,
                                style: TextStyle(
                                  color: AppColors.of(context).warning,
                                  fontSize: 11,
                                ),
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
        Text(
          value,
          style: TextStyle(
            color: AppColors.of(context).primary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
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
}

class _OverviewTab extends StatelessWidget {
  final Player player;
  final Team? team;
  final PlayerSummary? summary;
  final ScrollController? scrollController;

  const _OverviewTab({
    required this.player,
    this.team,
    this.summary,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(player.status);
    final statusLabel = formatStatusLabel(player.status);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Availability status banner
          if (player.status != 'a')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withAlpha(120)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (player.chanceOfPlayingNextRound != null)
                          Text(
                            'Chance of playing next GW: ${player.chanceOfPlayingNextRound}%',
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        if (player.news.isNotEmpty)
                          Text(
                            player.news,
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _buildStatsGrid(context),
          const SizedBox(height: 20),
          _buildExpectedStatsSection(context),
          const SizedBox(height: 20),
          _buildTransferSection(context),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final stats = [
      _StatItem(
        'Total Points',
        '${player.totalPoints}',
        Icons.star,
        AppColors.of(context).primary,
      ),
      _StatItem(
        'Form',
        formatForm(player.form),
        Icons.trending_up,
        AppColors.of(context).accent,
      ),
      _StatItem(
        'Price',
        formatPrice(player.nowCost),
        Icons.attach_money,
        const Color(0xFF69F0AE),
      ),
      _StatItem(
        'Selected %',
        formatPercent(player.selectedByPercent),
        Icons.people,
        const Color(0xFFB388FF),
      ),
      _StatItem(
        'Goals',
        '${player.goals}',
        Icons.sports_soccer,
        AppColors.of(context).primary,
      ),
      _StatItem(
        'Assists',
        '${player.assists}',
        Icons.sports,
        AppColors.of(context).accent,
      ),
      _StatItem(
        'Clean Sheets',
        '${player.cleanSheets}',
        Icons.shield,
        const Color(0xFF69F0AE),
      ),
      _StatItem(
        'Bonus Pts',
        '${player.bonus}',
        Icons.add_circle,
        AppColors.of(context).warning,
      ),
      _StatItem(
        'Minutes',
        '${player.minutes}',
        Icons.timer,
        AppColors.of(context).textSecondary,
      ),
      _StatItem(
        'Goals Conc.',
        '${player.goalsConceded}',
        Icons.sports_soccer_outlined,
        AppColors.of(context).error,
      ),
      _StatItem(
        'Yellow Cards',
        '${player.yellowCards}',
        Icons.square,
        AppColors.of(context).warning,
      ),
      _StatItem(
        'Saves',
        '${player.saves}',
        Icons.back_hand,
        AppColors.of(context).accent,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stats
          .map(
            (s) => Container(
              padding: const EdgeInsets.all(10),
              decoration: AppTheme.gradientCard(context: context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(s.icon, color: s.color, size: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.value,
                        style: TextStyle(
                          color: s.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildIctSection(BuildContext context) {
    final ict = double.tryParse(player.ictIndex) ?? 0;
    final influence = double.tryParse(player.influence) ?? 0;
    final creativity = double.tryParse(player.creativity) ?? 0;
    final threat = double.tryParse(player.threat) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ICT Index',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message:
                    'ICT = Influence + Creativity + Threat\n'
                    'A composite FPL score rating a player\'s\n'
                    'impact on a match.',
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.of(context).textSecondary,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Influence: ball involvement • Creativity: chance creation • Threat: goal threat',
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 14),
          _ictBar(
            context,
            'ICT Index',
            ict,
            200,
            AppColors.of(context).primary,
          ),
          const SizedBox(height: 10),
          _ictBar(
            context,
            'Influence',
            influence,
            200,
            AppColors.of(context).accent,
          ),
          const SizedBox(height: 10),
          _ictBar(
            context,
            'Creativity',
            creativity,
            200,
            const Color(0xFFB388FF),
          ),
          const SizedBox(height: 10),
          _ictBar(
            context,
            'Threat',
            threat,
            200,
            AppColors.of(context).warning,
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedStatsSection(BuildContext context) {
    final xg = double.tryParse(player.expectedGoalsStr) ?? 0;
    final xa = double.tryParse(player.expectedAssistsStr) ?? 0;
    final ppg = double.tryParse(player.pointsPerGame) ?? 0;
    final vsn = double.tryParse(player.valueSeason) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expected Stats & Value',
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
                child: _expectedStatTile(
                  context,
                  'Expected Goals\n(xG)',
                  xg.toStringAsFixed(2),
                  AppColors.of(context).primary,
                  'How many goals a player\nwas statistically expected to score',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _expectedStatTile(
                  context,
                  'Expected Assists\n(xA)',
                  xa.toStringAsFixed(2),
                  AppColors.of(context).accent,
                  'How many assists a player\nwas expected to provide',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _expectedStatTile(
                  context,
                  'Points Per Game\n(PPG)',
                  ppg.toStringAsFixed(1),
                  AppColors.of(context).warning,
                  'Average points scored per\ngameweek this season',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _expectedStatTile(
                  context,
                  'Value\n(pts per £m)',
                  vsn.toStringAsFixed(1),
                  const Color(0xFF69F0AE),
                  'Total points divided by\ncurrent price — higher is better',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _expectedStatTile(
    BuildContext context,
    String label,
    String value,
    Color color,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
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
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ictBar(
    BuildContext context,
    String label,
    double value,
    double maxVal,
    Color color,
  ) {
    final pct = (value / maxVal).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.of(context).cardMedium,
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
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTransferSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer Activity',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _transferStat(
                  context,
                  'In (Season)',
                  _formatCount(player.transfersIn),
                  Icons.arrow_upward,
                  AppColors.of(context).primary,
                ),
              ),
              Expanded(
                child: _transferStat(
                  context,
                  'Out (Season)',
                  _formatCount(player.transfersOut),
                  Icons.arrow_downward,
                  AppColors.of(context).error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _transferStat(
                  context,
                  'In (GW)',
                  _formatCount(player.transfersInEvent),
                  Icons.arrow_upward,
                  AppColors.of(context).primary,
                ),
              ),
              Expanded(
                child: _transferStat(
                  context,
                  'Out (GW)',
                  _formatCount(player.transfersOutEvent),
                  Icons.arrow_downward,
                  AppColors.of(context).error,
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

  Widget _transferStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 11,
              ),
            ),
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

class _HistoryTab extends StatefulWidget {
  final Player player;
  final PlayerSummary? summary;
  final FplProvider provider;
  final ScrollController? scrollController;

  const _HistoryTab({
    required this.player,
    this.summary,
    required this.provider,
    this.scrollController,
  });

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab>
    with SingleTickerProviderStateMixin {
  int _gwRange = 10; // 5, 10, 15, 20, 25, 30
  int _metricIndex = 0; // 0=Points, 1=Minutes, 2=Goals+Assists, 3=BPS
  late TabController _metricTabController;

  static const _ranges = [5, 10, 15, 20, 25, 30];
  static const _metricLabels = ['Points', 'Minutes', 'G+A', 'BPS'];

  @override
  void initState() {
    super.initState();
    _metricTabController =
        TabController(length: _metricLabels.length, vsync: this)
          ..addListener(() {
            if (!_metricTabController.indexIsChanging) {
              setState(() => _metricIndex = _metricTabController.index);
            }
          });
  }

  @override
  void dispose() {
    _metricTabController.dispose();
    super.dispose();
  }

  List<double> _getValues(List<PlayerHistory> history) {
    return history.map((h) {
      switch (_metricIndex) {
        case 0:
          return h.totalPoints.toDouble();
        case 1:
          return h.minutes.toDouble();
        case 2:
          return (h.goalsScored + h.assists).toDouble();
        case 3:
          return h.bps.toDouble();
        default:
          return h.totalPoints.toDouble();
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.summary == null) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.of(context).primary),
      );
    }
    if (widget.summary!.history.isEmpty) {
      return Center(
        child: Text(
          'No history available',
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    final allHistory = widget.summary!.history;
    final rangedHistory = allHistory.reversed
        .take(_gwRange)
        .toList()
        .reversed
        .toList();

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRangeSelector(),
          const SizedBox(height: 12),
          _buildMetricTabs(),
          const SizedBox(height: 12),
          _buildLineChart(rangedHistory),
          const SizedBox(height: 20),
          _buildHistoryTable(),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gameweek Range',
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _ranges.map((r) {
              final isSelected = _gwRange == r;
              final maxAvail = widget.summary?.history.length ?? 0;
              final isAvail = maxAvail >= r;
              return GestureDetector(
                onTap: isAvail ? () => setState(() => _gwRange = r) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.of(context).primary.withAlpha(30)
                        : isAvail
                        ? AppColors.of(context).cardMedium
                        : AppColors.of(context).cardMedium.withAlpha(80),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.of(context).primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    'Last $r',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.of(context).primary
                          : isAvail
                          ? AppColors.of(context).textSecondary
                          : AppColors.of(context).textSecondary.withAlpha(100),
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _metricTabController,
        isScrollable: true,
        padding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          color: AppColors.of(context).primary.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.of(context).primary.withAlpha(80),
          ),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.of(context).primary,
        unselectedLabelColor: AppColors.of(context).textSecondary,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        dividerColor: Colors.transparent,
        tabs: _metricLabels.map((l) => Tab(text: l, height: 30)).toList(),
      ),
    );
  }

  Widget _buildLineChart(List<PlayerHistory> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    final values = _getValues(history);
    final maxVal = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final metricColor = _metricColors(context)[_metricIndex];
    final metricLabel = _metricLabels[_metricIndex];
    final isDecimal = _metricIndex == 4;

    final spots = values.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: metricColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$metricLabel (Last $_gwRange GW)',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: metricColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, __, ___, ____) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: metricColor,
                            strokeWidth: 2,
                            strokeColor: AppColors.of(context).cardDark,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: metricColor.withAlpha(40),
                    ),
                    showingIndicators: List.generate(spots.length, (i) => i),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.of(context).cardDark,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final idx = s.x.toInt();
                        final gwNum = idx < history.length
                            ? history[idx].round
                            : '?';
                        return LineTooltipItem(
                          'GW$gwNum\n${s.y.toStringAsFixed(isDecimal ? 1 : 0)} $metricLabel',
                          TextStyle(
                            color: metricColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(isDecimal ? 1 : 0),
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
                      reservedSize: 24,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= history.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'GW${history[idx].round}',
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= values.length) {
                          return const SizedBox.shrink();
                        }
                        final val = values[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            val.toStringAsFixed(isDecimal ? 1 : 0),
                            style: TextStyle(
                              color: metricColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  verticalInterval: 1,
                  horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.of(context).divider,
                    strokeWidth: 0.8,
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: AppColors.of(context).divider,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.of(context).divider,
                    width: 0.5,
                  ),
                ),
                minY: 0,
                maxY: maxVal * 1.35 < 1 ? 2 : maxVal * 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _metricColors(BuildContext context) => [
    AppColors.of(context).primary,
    AppColors.of(context).accent,
    const Color(0xFF34D399),
    AppColors.of(context).warning,
    const Color(0xFFB388FF),
  ];

  Widget _buildHistoryTable() {
    return Container(
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.of(context).divider),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    'GW',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Opp',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    'Min',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    'Pts',
                    style: TextStyle(
                      color: AppColors.of(context).primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          ...widget.summary!.history.reversed.map(
            (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.of(context).divider,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${h.round}',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: _buildOpponentCell(h)),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${h.minutes}',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${h.goalsScored}',
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${h.assists}',
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${h.totalPoints}',
                      style: TextStyle(
                        color: h.totalPoints >= 8
                            ? AppColors.of(context).primary
                            : h.totalPoints >= 6
                            ? AppColors.of(context).accent
                            : AppColors.of(context).textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentCell(PlayerHistory h) {
    final opp = widget.provider.getTeamById(h.opponentTeam);
    final badgeColor = h.wasHome
        ? AppColors.of(context).primary
        : AppColors.of(context).accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: badgeColor.withAlpha(20),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: badgeColor.withAlpha(60)),
          ),
          child: Text(
            h.wasHome ? 'H' : 'A',
            style: TextStyle(
              color: badgeColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (opp != null)
          CachedNetworkImage(
            imageUrl: opp.badgeUrl,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            placeholder: (_, __) => const SizedBox(width: 16, height: 16),
            errorWidget: (_, __, ___) => const SizedBox(width: 16, height: 16),
          ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            opp?.shortName ?? '${h.opponentTeam}',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FixturesTab extends StatelessWidget {
  final Player player;
  final PlayerSummary? summary;
  final FplProvider provider;
  final ScrollController? scrollController;

  const _FixturesTab({
    required this.player,
    this.summary,
    required this.provider,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.of(context).primary),
      );
    }
    if (summary!.fixtures.isEmpty) {
      return Center(
        child: Text(
          'No upcoming fixtures',
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      itemCount: summary!.fixtures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final fixture = summary!.fixtures[i];
        final isHome = fixture.isHome;
        final opponentId = isHome ? fixture.teamA : fixture.teamH;
        final opponent = provider.getTeamById(opponentId);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.gradientCard(context: context),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.of(context).cardMedium,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'GW${fixture.event}',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    if (opponent != null) ...[
                      CachedNetworkImage(
                        imageUrl: opponent.badgeUrl,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            const SizedBox(width: 24, height: 24),
                        errorWidget: (_, __, ___) =>
                            const SizedBox(width: 24, height: 24),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      opponent?.shortName ?? '?',
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.of(context).cardMedium,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isHome ? 'Home' : 'Away',
                        style: TextStyle(
                          color: isHome
                              ? AppColors.of(context).primary
                              : AppColors.of(context).textSecondary,
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
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 12,
                ),
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
