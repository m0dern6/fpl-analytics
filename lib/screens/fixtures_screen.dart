import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fpl_provider.dart';
import '../models/fixture.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import '../widgets/fixture_card.dart';

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
    final currentGw = provider.currentGameweek?.id ?? 1;
    final currentGwFixtures = provider.fixtures.where((f) => f.event == currentGw).toList();
    final allCurrentMatchesPlayed = currentGwFixtures.isNotEmpty &&
        currentGwFixtures.every((f) => f.isFinished);
    final targetGw = allCurrentMatchesPlayed
        ? (provider.gameweeks.where((g) => g.isNext).firstOrNull?.id ?? (currentGw + 1).clamp(1, _totalGws))
        : currentGw;

    _selectedGw = widget.initialGameweek ?? targetGw;
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
        final currentGw = provider.currentGameweek?.id ?? 1;
        final currentGwFixtures = provider.fixtures.where((f) => f.event == currentGw).toList();
        final allCurrentMatchesPlayed = currentGwFixtures.isNotEmpty &&
            currentGwFixtures.every((f) => f.isFinished);
        final targetGw = allCurrentMatchesPlayed
            ? (provider.gameweeks.where((g) => g.isNext).firstOrNull?.id ?? (currentGw + 1).clamp(1, _totalGws))
            : currentGw;

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
                final isTarget = gwId == targetGw;

                return Tab(
                  child: Container(
                    key: _tabKeys[i],
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GW$gwId',
                          style: TextStyle(
                            fontWeight: isTarget ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                        if (isTarget) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.of(context).primary,
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

class _GwFixturesList extends StatefulWidget {
  final int gwId;
  final FplProvider provider;

  const _GwFixturesList({required this.gwId, required this.provider});

  @override
  State<_GwFixturesList> createState() => _GwFixturesListState();
}

class _GwFixturesListState extends State<_GwFixturesList> {
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _startLiveTimer();
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final fixtures = widget.provider.getFixturesForGameweek(widget.gwId);
      final hasLive = fixtures.any((f) => f.isLive);
      if (hasLive) {
        widget.provider.updateFixturesForGameweek(widget.gwId);
      }
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fixtures = widget.provider.getFixturesForGameweek(widget.gwId);

    if (widget.provider.isLoading) {
      return const LoadingListWidget(itemCount: 5);
    }

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
              'GW${widget.gwId} fixtures not available yet',
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
          ],
        ),
      );
    }

    // Group fixtures by local calendar day
    final Map<String, List<Fixture>> groupedByDay = {};
    for (final f in fixtures) {
      final dateStr = f.kickoffTime != null
          ? formatDateShort(f.kickoffTime!)
          : 'TBC';
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
              provider: widget.provider,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }
}
