import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../models/fixture.dart';
import '../models/team.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import '../widgets/difficulty_badge.dart';
import 'fixture_detail_screen.dart';

class FixturesScreen extends StatefulWidget {
  final int? initialGameweek;

  const FixturesScreen({super.key, this.initialGameweek});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedGw = 1;
  bool _didAutoScroll = false;
  static const int _totalGws = 38;
  late final List<GlobalKey> _tabKeys = List.generate(
    _totalGws,
    (_) => GlobalKey(),
  );

  @override
  void initState() {
    super.initState();
    final provider = context.read<FplProvider>();
    _selectedGw = widget.initialGameweek ?? (provider.currentGameweek?.id ?? 1);
    _tabController = TabController(
      length: _totalGws,
      vsync: this,
      initialIndex: _selectedGw - 1,
    );
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
        if (!_didAutoScroll && provider.gameweeks.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final target = _tabKeys[_selectedGw - 1].currentContext;
            if (target != null) {
              Scrollable.ensureVisible(
                target,
                alignment: 0.5,
                duration: Duration.zero,
              );
            }
            _didAutoScroll = true;
          });
        }
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Fixtures'),
            backgroundColor: AppColors.of(context).secondary,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: List.generate(_totalGws, (i) {
                final gwId = i + 1;
                final gw = provider.gameweeks.length > i
                    ? provider.gameweeks[i]
                    : null;
                final isCurrent = gw?.isCurrent ?? false;
                final isNext = gw?.isNext ?? false;
                return Tab(
                  child: Container(
                    key: _tabKeys[i],
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
                            decoration: BoxDecoration(
                              color: AppColors.of(context).primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ] else if (isNext) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.of(context).accent,
                              shape: BoxShape.circle,
                            ),
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
            Icon(
              Icons.sports_soccer,
              color: AppColors.of(context).textSecondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'GW$gwId fixtures not available yet',
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fixtures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          _FixtureCard(fixture: fixtures[i], provider: provider),
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
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.gradientCard(context: context, ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _teamDisplay(context, home, fixture.teamHDifficulty, true),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).cardMedium,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.of(context).divider),
                  ),
                  child: fixture.hasResult
                      ? Text(
                          '${fixture.homeTeamScore} - ${fixture.awayTeamScore}',
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : Column(
                          children: [
                            Text(
                              fixture.kickoffTime != null
                                  ? formatDateShort(fixture.kickoffTime)
                                  : 'TBC',
                              style: TextStyle(
                                color: AppColors.of(context).textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              fixture.kickoffTime != null
                                  ? _extractTime(fixture.kickoffTime!)
                                  : '',
                              style: TextStyle(
                                color: AppColors.of(context).textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                ),
                Expanded(
                  child: _teamDisplay(context, away, fixture.teamADifficulty, false),
                ),
              ],
            ),
            if (!fixture.finished && fixture.kickoffTime != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.of(context).textSecondary,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatDateTime(fixture.kickoffTime),
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _teamDisplay(BuildContext context, Team? team, int difficulty, bool isHome) {
    final badge = CachedNetworkImage(
      imageUrl: team?.badgeUrl ?? '',
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      placeholder: (_, __) => const SizedBox(width: 32, height: 32),
      errorWidget: (_, __, ___) => const SizedBox(width: 32, height: 32),
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: isHome
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: isHome
              ? [
                  Text(
                    team?.shortName ?? '?',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  badge,
                ]
              : [
                  badge,
                  const SizedBox(width: 6),
                  Text(
                    team?.shortName ?? '?',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: isHome
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            DifficultyBadge(difficulty: difficulty, size: 24),
            const SizedBox(width: 4),
            Text(
              isHome ? 'H' : 'A',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 10,
              ),
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
