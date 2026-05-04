import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../providers/fpl_entry_provider.dart';
import '../models/player.dart';
import '../models/entry.dart';
import '../logic/fpl_rules.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import 'player_detail_screen.dart';
import 'onboarding_screen.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final fplProvider = context.read<FplProvider>();
    final entryProvider = context.read<FplEntryProvider>();
    final gw = fplProvider.currentGameweek?.id;
    if (gw != null) {
      await fplProvider.loadLiveGwData(gw);
      if (entryProvider.hasEntry) {
        final positions = {
          for (final p in fplProvider.players) p.id: p.elementType,
        };
        await entryProvider.loadLiveData(
          gw,
          gameweeks: fplProvider.gameweeks,
          playerPositions: positions,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FplProvider, FplEntryProvider>(
      builder: (context, fplProvider, entryProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            backgroundColor: AppColors.of(context).secondary,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5A0), Color(0xFF00A87A)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.live_tv_rounded,
                      color: Color(0xFF0C0720),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Live'),
                if (fplProvider.currentGameweek != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.of(context).primary.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      'GW${fplProvider.currentGameweek!.id}',
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.of(context).textSecondary,
                ),
                onPressed: _refresh,
                tooltip: 'Refresh live data',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'My Team'),
                Tab(text: 'Gameweek'),
              ],
            ),
          ),
          body: fplProvider.isLoading
              ? const LoadingWidget(height: 400)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _MyTeamLiveTab(
                      fplProvider: fplProvider,
                      entryProvider: entryProvider,
                    ),
                    _GameweekLiveTab(fplProvider: fplProvider),
                  ],
                ),
        );
      },
    );
  }
}

// ── My Team Live Tab ───────────────────────────────────────────────────────────

class _MyTeamLiveTab extends StatelessWidget {
  final FplProvider fplProvider;
  final FplEntryProvider entryProvider;

  const _MyTeamLiveTab({
    required this.fplProvider,
    required this.entryProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (!entryProvider.hasEntry) {
      return _NoEntryPrompt(
        onLink: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        ),
      );
    }

    final picks = entryProvider.currentPicks;
    if (picks == null) {
      return const Center(child: LoadingWidget(height: 200));
    }

    final playerPositions = {
      for (final p in fplProvider.players) p.id: p.elementType,
    };
    final autoSubs = entryProvider.predictAutoSubsWithPositions(playerPositions);
    final captainPick = picks.captain;
    final vicePick = picks.viceCaptain;

    return RefreshIndicator(
      color: AppColors.of(context).primary,
      backgroundColor: AppColors.of(context).cardDark,
      onRefresh: () async {
        final gw = fplProvider.currentGameweek?.id;
        if (gw != null) {
          await fplProvider.loadLiveGwData(gw);
          await entryProvider.loadLiveData(
            gw,
            gameweeks: fplProvider.gameweeks,
            playerPositions: playerPositions,
          );
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LiveScoreSummaryCard(
              entryProvider: entryProvider,
              picks: picks,
            ),
            const SizedBox(height: 16),
            if (picks.activeChipName != null) ...[
              _ActiveChipBanner(chipName: picks.activeChipName!),
              const SizedBox(height: 12),
            ],
            _buildCaptainCard(context, captainPick, vicePick),
            const SizedBox(height: 16),
            _buildSquadSection(
              context,
              'Starting XI',
              picks.startingPicks,
              autoSubs,
            ),
            const SizedBox(height: 16),
            _buildSquadSection(
              context,
              'Bench',
              picks.benchPicks,
              autoSubs,
              isBench: true,
            ),
            if (autoSubs.subs.isNotEmpty) ...[
              const SizedBox(height: 16),
              _AutoSubsCard(
                subs: autoSubs,
                fplProvider: fplProvider,
              ),
            ],
            const SizedBox(height: 16),
            _buildLimitationsNote(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptainCard(
    BuildContext context,
    EntryPick? captain,
    EntryPick? vice,
  ) {
    if (captain == null) return const SizedBox.shrink();

    final captainPlayer = fplProvider.getPlayerById(captain.element);
    final captainLive = entryProvider.getLiveElement(captain.element);
    final vicePlayer = vice != null ? fplProvider.getPlayerById(vice.element) : null;
    final viceLive = vice != null ? entryProvider.getLiveElement(vice.element) : null;

    final captainStats = LivePlayerStats(
      playerId: captain.element,
      minutes: captainLive?.minutes ?? 0,
      rawPoints: captainLive?.totalPoints ?? 0,
    );
    final viceStats = vice != null
        ? LivePlayerStats(
            playerId: vice.element,
            minutes: viceLive?.minutes ?? 0,
            rawPoints: viceLive?.totalPoints ?? 0,
          )
        : LivePlayerStats(playerId: 0, minutes: 0, rawPoints: 0);

    final gwHasStarted = entryProvider.liveStats.values.any((s) => s.minutes > 0);
    final captainResult = resolveCaptain(
      captainStats: captainStats,
      viceCaptainStats: viceStats,
      gwHasStarted: gwHasStarted,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Captain / Vice-captain',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CaptainMiniCard(
                player: captainPlayer,
                live: captainLive,
                label: captainResult.usingVice ? '©ᵛ VICE' : '©',
                isEffective: captainResult.captainId == captain.element,
                context: context,
              ),
              const SizedBox(width: 12),
              if (vice != null)
                _CaptainMiniCard(
                  player: vicePlayer,
                  live: viceLive,
                  label: captainResult.usingVice ? 'VC (Captaining)' : 'VC',
                  isEffective: captainResult.captainId == vice.element,
                  context: context,
                ),
            ],
          ),
          if (captainResult.usingVice) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.of(context).warning.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.of(context).warning.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.of(context).warning,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Captain did not play — vice-captain doubled',
                    style: TextStyle(
                      color: AppColors.of(context).warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSquadSection(
    BuildContext context,
    String title,
    List<EntryPick> picks,
    AutoSubResult autoSubs, {
    bool isBench = false,
  }) {
    if (picks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.of(context).primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...picks.map((pick) => _LivePlayerRow(
              pick: pick,
              player: fplProvider.getPlayerById(pick.element),
              liveStats: entryProvider.getLiveElement(pick.element),
              isSubbedOff: autoSubs.subs.containsKey(pick.element),
              subbedOnId: autoSubs.subs[pick.element],
              subbedOnPlayer: autoSubs.subs.containsKey(pick.element)
                  ? fplProvider.getPlayerById(autoSubs.subs[pick.element]!)
                  : null,
              isBench: isBench,
            )),
      ],
    );
  }

  Widget _buildLimitationsNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.of(context).textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Overall live rank is not available from the official API without crawling millions of entries. Bonus points shown are provisional — official BPS awarded after match ends.',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gameweek Tab ───────────────────────────────────────────────────────────────

class _GameweekLiveTab extends StatelessWidget {
  final FplProvider fplProvider;

  const _GameweekLiveTab({required this.fplProvider});

  @override
  Widget build(BuildContext context) {
    final gw = fplProvider.currentGameweek;
    if (gw == null) {
      return const Center(child: Text('No active gameweek'));
    }

    // Top scorers in live data
    final liveTopPlayers = fplProvider.players
        .where((p) => fplProvider.getLiveStatsForPlayer(p.id) != null)
        .toList()
      ..sort((a, b) {
        final aLive = fplProvider.getLiveStatsForPlayer(a.id)?.totalPoints ?? 0;
        final bLive = fplProvider.getLiveStatsForPlayer(b.id)?.totalPoints ?? 0;
        return bLive.compareTo(aLive);
      });

    if (liveTopPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_rounded,
                color: AppColors.of(context).textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              'No live data yet',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Live scores will appear here once matches start.',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: liveTopPlayers.take(50).length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${gw.name} — Top Performers',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final player = liveTopPlayers[index - 1];
        final live = fplProvider.getLiveStatsForPlayer(player.id);
        if (live == null) return const SizedBox.shrink();

        return _LiveTopPlayerRow(
          player: player,
          live: live,
          rank: index,
          fplProvider: fplProvider,
        );
      },
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────────

class _LiveScoreSummaryCard extends StatelessWidget {
  final FplEntryProvider entryProvider;
  final EntryGwPicks picks;

  const _LiveScoreSummaryCard({
    required this.entryProvider,
    required this.picks,
  });

  @override
  Widget build(BuildContext context) {
    final livePoints = entryProvider.livePoints;
    final benchPoints = entryProvider.liveBenchPoints;
    final hitCost = picks.eventTransfersCost;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00E5A0), Color(0xFF00A87A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5A0).withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            entryProvider.displayTeamName,
            style: const TextStyle(
              color: Color(0xFF0C0720),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$livePoints',
            style: const TextStyle(
              color: Color(0xFF0C0720),
              fontSize: 52,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Text(
            'LIVE POINTS',
            style: TextStyle(
              color: Color(0xFF0C0720),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                label: 'Bench',
                value: '$benchPoints pts',
                color: Colors.black26,
              ),
              if (hitCost < 0)
                _StatChip(
                  label: 'Hits',
                  value: '$hitCost pts',
                  color: Colors.red.withAlpha(80),
                ),
              _StatChip(
                label: 'Transfers',
                value: '${picks.eventTransfers}',
                color: Colors.black26,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0C0720),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0C0720),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChipBanner extends StatelessWidget {
  final String chipName;

  const _ActiveChipBanner({required this.chipName});

  String get displayName {
    switch (chipName) {
      case ChipNames.wildcard:
        return '🃏 Wildcard Active';
      case ChipNames.freeHit:
        return '🎯 Free Hit Active';
      case ChipNames.benchBoost:
        return '⬆️ Bench Boost Active';
      case ChipNames.tripleCaptain:
        return '3️⃣ Triple Captain Active';
      default:
        return chipName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.of(context).accent.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).accent.withAlpha(80)),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          color: AppColors.of(context).accent,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CaptainMiniCard extends StatelessWidget {
  final Player? player;
  final LiveElementStats? live;
  final String label;
  final bool isEffective;
  final BuildContext context;

  const _CaptainMiniCard({
    required this.player,
    required this.live,
    required this.label,
    required this.isEffective,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final minutes = live?.minutes ?? 0;
    final points = live?.totalPoints ?? 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEffective
              ? colors.primary.withAlpha(20)
              : colors.cardMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEffective
                ? colors.primary.withAlpha(80)
                : colors.divider,
            width: isEffective ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isEffective ? colors.primary : colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              player?.webName ?? '—',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$points pts · ${minutes}m',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePlayerRow extends StatelessWidget {
  final EntryPick pick;
  final Player? player;
  final LiveElementStats? liveStats;
  final bool isSubbedOff;
  final int? subbedOnId;
  final Player? subbedOnPlayer;
  final bool isBench;

  const _LivePlayerRow({
    required this.pick,
    required this.player,
    required this.liveStats,
    required this.isSubbedOff,
    this.subbedOnId,
    this.subbedOnPlayer,
    required this.isBench,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final points = liveStats?.totalPoints ?? 0;
    final minutes = liveStats?.minutes ?? 0;
    final events = liveStats?.eventDescriptions ?? [];

    final isCaptain = pick.isCaptain;
    final isVice = pick.isViceCaptain;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSubbedOff
            ? colors.error.withAlpha(15)
            : isBench
                ? colors.cardMedium
                : colors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubbedOff ? colors.error.withAlpha(60) : colors.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.cardMedium,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCaptain
                        ? colors.primary
                        : isVice
                            ? colors.accent
                            : colors.divider,
                    width: isCaptain || isVice ? 2 : 1,
                  ),
                ),
                child: player != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: player!.photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.person,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      )
                    : Icon(Icons.person, size: 18, color: colors.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player?.webName ?? 'Unknown',
                          style: TextStyle(
                            color: isSubbedOff
                                ? colors.textSecondary
                                : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: isSubbedOff
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (isCaptain) ...[
                          const SizedBox(width: 4),
                          _Badge('C', colors.primary),
                        ] else if (isVice) ...[
                          const SizedBox(width: 4),
                          _Badge('V', colors.accent),
                        ],
                      ],
                    ),
                    if (events.isNotEmpty)
                      Text(
                        events.join(' · '),
                        style: TextStyle(
                          color: colors.textSecondary,
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
                    '$points',
                    style: TextStyle(
                      color: points > 0 ? colors.primary : colors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${minutes}m',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isSubbedOff && subbedOnPlayer != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 42),
                Icon(Icons.arrow_downward_rounded,
                    color: colors.error, size: 14),
                const SizedBox(width: 4),
                Icon(Icons.arrow_upward_rounded,
                    color: colors.primary, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${subbedOnPlayer!.webName} comes on',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AutoSubsCard extends StatelessWidget {
  final AutoSubResult subs;
  final FplProvider fplProvider;

  const _AutoSubsCard({required this.subs, required this.fplProvider});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Predicted Auto-subs',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...subs.subs.entries.map((e) {
            final outP = fplProvider.getPlayerById(e.key);
            final inP = fplProvider.getPlayerById(e.value);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(Icons.arrow_downward_rounded,
                      color: colors.error, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    outP?.webName ?? e.key.toString(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_upward_rounded,
                      color: colors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    inP?.webName ?? e.value.toString(),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

class _LiveTopPlayerRow extends StatelessWidget {
  final Player player;
  final LiveElementStats live;
  final int rank;
  final FplProvider fplProvider;

  const _LiveTopPlayerRow({
    required this.player,
    required this.live,
    required this.rank,
    required this.fplProvider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final team = fplProvider.getTeamById(player.teamId);
    final events = live.eventDescriptions;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CachedNetworkImage(
              imageUrl: player.photoUrl,
              width: 36,
              height: 36,
              imageBuilder: (_, img) => ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image(image: img, fit: BoxFit.cover),
              ),
              errorWidget: (_, __, ___) => CircleAvatar(
                radius: 18,
                backgroundColor: colors.cardMedium,
                child: Icon(Icons.person, color: colors.textSecondary, size: 18),
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
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${team?.shortName ?? ''} · ${live.minutes}m',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (events.isNotEmpty)
                    Text(
                      events.join(' · '),
                      style: TextStyle(
                        color: colors.textSecondary,
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
                  '${live.totalPoints}',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'pts',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoEntryPrompt extends StatelessWidget {
  final VoidCallback onLink;

  const _NoEntryPrompt({required this.onLink});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv_rounded, color: colors.primary, size: 64),
            const SizedBox(height: 20),
            Text(
              'Link Your FPL Team',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your FPL Entry ID to see live points, auto-subs, and captain resolution for your team.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onLink,
              icon: const Icon(Icons.link_rounded),
              label: const Text(
                'Link Team',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
