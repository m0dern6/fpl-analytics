import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fpl_provider.dart';
import '../models/fixture.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import '../widgets/difficulty_badge.dart';

class FixturesScreen extends StatefulWidget {
  final int? initialGameweek;

  const FixturesScreen({super.key, this.initialGameweek});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedGw = 1;
  static const int _totalGws = 38;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FplProvider>();
    _selectedGw = widget.initialGameweek ?? (provider.currentGameweek?.id ?? 1);
    _tabController = TabController(length: _totalGws, vsync: this, initialIndex: _selectedGw - 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedGw = _tabController.index + 1);
      }
    });
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
            title: const Text('Fixtures'),
            backgroundColor: AppColors.secondary,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: List.generate(_totalGws, (i) {
                final gwId = i + 1;
                final gw = provider.gameweeks.length > i ? provider.gameweeks[i] : null;
                final isCurrent = gw?.isCurrent ?? false;
                final isNext = gw?.isNext ?? false;
                return Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('GW$gwId'),
                        if (isCurrent) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                        ] else if (isNext) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: List.generate(_totalGws, (i) {
              final gwId = i + 1;
              return _GwFixturesList(gwId: gwId, provider: provider);
            }),
          ),
        );
      },
    );
  }
}

class _GwFixturesList extends StatelessWidget {
  final int gwId;
  final FplProvider provider;

  const _GwFixturesList({required this.gwId, required this.provider});

  @override
  Widget build(BuildContext context) {
    final fixtures = provider.getFixturesForGameweek(gwId);

    if (provider.isLoading) return const LoadingListWidget(itemCount: 5);

    if (fixtures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text('GW$gwId fixtures not available yet', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fixtures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _FixtureCard(fixture: fixtures[i], provider: provider),
    );
  }
}

class _FixtureCard extends StatelessWidget {
  final Fixture fixture;
  final FplProvider provider;

  const _FixtureCard({required this.fixture, required this.provider});

  @override
  Widget build(BuildContext context) {
    final home = provider.getTeamById(fixture.homeTeamId);
    final away = provider.getTeamById(fixture.awayTeamId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _teamDisplay(home?.shortName ?? '?', fixture.teamHDifficulty, true),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardMedium,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: fixture.hasResult
                    ? Text(
                        '${fixture.homeTeamScore} - ${fixture.awayTeamScore}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      )
                    : Column(
                        children: [
                          Text(
                            fixture.kickoffTime != null ? formatDateShort(fixture.kickoffTime) : 'TBC',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            fixture.kickoffTime != null ? _extractTime(fixture.kickoffTime!) : '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
              ),
              Expanded(
                child: _teamDisplay(away?.shortName ?? '?', fixture.teamADifficulty, false),
              ),
            ],
          ),
          if (!fixture.finished && fixture.kickoffTime != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: AppColors.textSecondary, size: 12),
                const SizedBox(width: 4),
                Text(
                  formatDateTime(fixture.kickoffTime),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamDisplay(String shortName, int difficulty, bool isHome) {
    return Column(
      children: [
        Text(
          shortName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          textAlign: isHome ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            DifficultyBadge(difficulty: difficulty, size: 24),
            const SizedBox(width: 4),
            Text(
              isHome ? 'H' : 'A',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  String _extractTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
