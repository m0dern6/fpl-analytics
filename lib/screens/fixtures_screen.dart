import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../providers/fpl_provider.dart';
import '../models/fixture.dart';
import '../models/team.dart';
import '../utils/app_theme.dart';
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

class _GwFixturesList extends StatefulWidget {
  final int gwId;
  final FplProvider provider;

  const _GwFixturesList({required this.gwId, required this.provider});

  @override
  State<_GwFixturesList> createState() => _GwFixturesListState();
}

class _GwFixturesListState extends State<_GwFixturesList> {
  Timer? _liveRefreshTimer;

  @override
  void initState() {
    super.initState();
    _liveRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final fixtures = widget.provider.getFixturesForGameweek(widget.gwId);
      final hasLive = fixtures.any((f) => f.isLive);
      if (!hasLive) return;
      widget.provider.refreshFixturesForGameweek(widget.gwId);
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fixtures = widget.provider.getFixturesForGameweek(widget.gwId);

    if (widget.provider.isLoading) return const LoadingListWidget(itemCount: 5);

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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fixtures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          FixtureCard(fixture: fixtures[i], provider: widget.provider),
    );
  }
}
