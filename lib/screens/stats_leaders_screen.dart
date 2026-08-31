import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                  ],
                ),
        );
      },
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildLeadersList(context),
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
                        fontWeight:
                            i == 0 ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Player photo — rounded rectangle (not circle)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.of(context).cardMedium,
                      border: Border.all(color: posColor, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
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
