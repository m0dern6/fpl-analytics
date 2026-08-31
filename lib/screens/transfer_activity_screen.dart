import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'player_detail_screen.dart';

enum TransferTab { transfersIn, transfersOut, netTransfers }

class TransferActivityScreen extends StatefulWidget {
  final int? initialGameweek;

  const TransferActivityScreen({super.key, this.initialGameweek});

  @override
  State<TransferActivityScreen> createState() => _TransferActivityScreenState();
}

class _TransferActivityScreenState extends State<TransferActivityScreen> {
  int? _selectedGw; // null means Season Overall
  TransferTab _currentTab = TransferTab.transfersIn;
  int _selectedPosition = 0; // 0: All, 1: GK, 2: DEF, 3: MID, 4: FWD
  String _searchQuery = '';
  int _visibleCount = 20;
  bool _didAutoScroll = false;
  final ScrollController _gwScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const int _totalGws = 38;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FplProvider>();
    final currentGw = provider.currentGameweek?.id ?? 1;
    final isLive = provider.currentGameweek?.isCurrent == true &&
        !(provider.currentGameweek?.finished ?? false);

    // When gameweek is live, highlight and target the upcoming week
    final nextGw = provider.gameweeks.where((g) => g.isNext).firstOrNull?.id ??
        (currentGw + 1).clamp(1, _totalGws);
    final targetGw = isLive ? nextGw : currentGw;

    _selectedGw = widget.initialGameweek ?? targetGw;
  }

  @override
  void dispose() {
    _gwScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTargetGw(int targetGw) {
    if (_didAutoScroll) return;
    _didAutoScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gwScrollController.hasClients) return;
      final targetOffset = (targetGw * 78.0) - 120.0;
      _gwScrollController.animateTo(
        targetOffset.clamp(0.0, _gwScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final currentGw = provider.currentGameweek?.id ?? 1;
        final isLive = provider.currentGameweek?.isCurrent == true &&
            !(provider.currentGameweek?.finished ?? false);
        final nextGw = provider.gameweeks.where((g) => g.isNext).firstOrNull?.id ??
            (currentGw + 1).clamp(1, _totalGws);

        final targetGw = isLive ? nextGw : currentGw;
        _scrollToTargetGw(targetGw);

        final isSeason = _selectedGw == null;

        // Top summary players
        final topInPlayer = (List<Player>.from(provider.players)
              ..sort((a, b) => (isSeason ? b.transfersIn : b.transfersInEvent)
                  .compareTo(isSeason ? a.transfersIn : a.transfersInEvent)))
            .firstOrNull;
        final topOutPlayer = (List<Player>.from(provider.players)
              ..sort((a, b) => (isSeason ? b.transfersOut : b.transfersOutEvent)
                  .compareTo(isSeason ? a.transfersOut : a.transfersOutEvent)))
            .firstOrNull;

        // Filter and sort players based on active tab
        List<MapEntry<Player, int>> sortedList;
        switch (_currentTab) {
          case TransferTab.transfersIn:
            sortedList = provider.players
                .map((p) => MapEntry(p, isSeason ? p.transfersIn : p.transfersInEvent))
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            break;
          case TransferTab.transfersOut:
            sortedList = provider.players
                .map((p) => MapEntry(p, isSeason ? p.transfersOut : p.transfersOutEvent))
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            break;
          case TransferTab.netTransfers:
            sortedList = provider.players
                .map((p) => MapEntry(
                      p,
                      isSeason
                          ? (p.transfersIn - p.transfersOut)
                          : (p.transfersInEvent - p.transfersOutEvent),
                    ))
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            break;
        }

        // Apply position filter
        if (_selectedPosition > 0) {
          sortedList = sortedList
              .where((e) => e.key.elementType == _selectedPosition)
              .toList();
        }

        // Apply search filter
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase().trim();
          sortedList = sortedList
              .where((e) =>
                  e.key.webName.toLowerCase().contains(q) ||
                  e.key.firstName.toLowerCase().contains(q) ||
                  e.key.secondName.toLowerCase().contains(q))
              .toList();
        }

        final visiblePlayers = sortedList.take(_visibleCount).toList();
        final canShowMore = _visibleCount < sortedList.length;

        String headerTag;
        if (isSeason) {
          headerTag = 'Season Transfers';
        } else if (_selectedGw == targetGw && isLive) {
          headerTag = 'GW$_selectedGw (Upcoming)';
        } else {
          headerTag = 'GW$_selectedGw Transfers';
        }

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Transfer Activity'),
            backgroundColor: AppColors.of(context).secondary,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.of(context).primary.withAlpha(70),
                  ),
                ),
                child: Text(
                  headerTag,
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Gameweek Selector (Season, GW1..GW38)
              _buildGameweekSelector(context, targetGw),
              // Segmented Tab Switcher
              _buildTabSwitcher(context),
              // Highlights Row
              if (_searchQuery.isEmpty && _selectedPosition == 0)
                _buildHighlights(context, topInPlayer, topOutPlayer, isSeason),
              // Filter & Search Header
              _buildFilterHeader(context),
              // Players List
              Expanded(
                child: visiblePlayers.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visiblePlayers.length +
                            (canShowMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == visiblePlayers.length) {
                            return _buildShowMoreButton();
                          }
                          final entry = visiblePlayers[index];
                          return _buildPlayerCard(
                            context,
                            provider,
                            entry.key,
                            entry.value,
                            index + 1,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Gameweek Selector ───────────────────────────────────────────────────────

  Widget _buildGameweekSelector(BuildContext context, int highlightedGw) {
    return Container(
      color: AppColors.of(context).secondary,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        controller: _gwScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            // Overall Season Pill
            _buildGwPill(
              context,
              label: 'Season',
              isSelected: _selectedGw == null,
              isHighlighted: false,
              onTap: () => setState(() {
                _selectedGw = null;
                _visibleCount = 20;
              }),
            ),
            const SizedBox(width: 8),
            // GW 1 to GW 38 Pills
            ...List.generate(_totalGws, (i) {
              final gwId = i + 1;
              final isHighlighted = gwId == highlightedGw;
              final isSelected = _selectedGw == gwId;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildGwPill(
                  context,
                  label: 'GW$gwId',
                  isSelected: isSelected,
                  isHighlighted: isHighlighted,
                  onTap: () => setState(() {
                    _selectedGw = gwId;
                    _visibleCount = 20;
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGwPill(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    final primaryColor = AppColors.of(context).primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isHighlighted
                  ? primaryColor.withAlpha(24)
                  : AppColors.of(context).cardMedium),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isHighlighted ? primaryColor : AppColors.of(context).divider),
            width: isHighlighted || isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF0C0720)
                    : (isHighlighted
                        ? primaryColor
                        : AppColors.of(context).textSecondary),
                fontSize: 12,
                fontWeight: (isSelected || isHighlighted)
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
            if (isHighlighted && !isSelected) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tab Switcher ───────────────────────────────────────────────────────────

  Widget _buildTabSwitcher(BuildContext context) {
    return Container(
      color: AppColors.of(context).secondary,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardMedium,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentButton(
                context,
                title: 'Transfers In',
                icon: Icons.arrow_circle_up_rounded,
                tab: TransferTab.transfersIn,
                activeColor: AppColors.of(context).primary,
              ),
            ),
            Expanded(
              child: _buildSegmentButton(
                context,
                title: 'Transfers Out',
                icon: Icons.arrow_circle_down_rounded,
                tab: TransferTab.transfersOut,
                activeColor: AppColors.of(context).error,
              ),
            ),
            Expanded(
              child: _buildSegmentButton(
                context,
                title: 'Net Flow',
                icon: Icons.swap_vert_rounded,
                tab: TransferTab.netTransfers,
                activeColor: const Color(0xFF60A5FA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required TransferTab tab,
    required Color activeColor,
  }) {
    final isSelected = _currentTab == tab;

    return GestureDetector(
      onTap: () => setState(() {
        _currentTab = tab;
        _visibleCount = 20;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? activeColor
                  : AppColors.of(context).textSecondary,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? activeColor
                    : AppColors.of(context).textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Highlights Banner ──────────────────────────────────────────────────────

  Widget _buildHighlights(
    BuildContext context,
    Player? topIn,
    Player? topOut,
    bool isSeason,
  ) {
    if (topIn == null || topOut == null) return const SizedBox.shrink();

    final inCount = isSeason ? topIn.transfersIn : topIn.transfersInEvent;
    final outCount = isSeason ? topOut.transfersOut : topOut.transfersOutEvent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniHighlightCard(
              context,
              title: 'Most Transferred In',
              player: topIn,
              count: inCount,
              color: AppColors.of(context).primary,
              icon: Icons.trending_up_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMiniHighlightCard(
              context,
              title: 'Most Transferred Out',
              player: topOut,
              count: outCount,
              color: AppColors.of(context).error,
              icon: Icons.trending_down_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniHighlightCard(
    BuildContext context, {
    required String title,
    required Player player,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withAlpha(18),
              AppColors.of(context).cardDark,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.of(context).cardMedium,
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: player.photoUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Icon(Icons.person, size: 16, color: color),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    player.webName,
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    formatNumber(count),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filters & Search ────────────────────────────────────────────────────────

  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.of(context).cardMedium,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.of(context).divider),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Search player or team...',
                hintStyle: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.of(context).textSecondary,
                  size: 18,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPosChip(0, 'All Positions'),
                const SizedBox(width: 8),
                _buildPosChip(1, 'GKs', const Color(0xFF34D399)),
                const SizedBox(width: 8),
                _buildPosChip(2, 'DEFs', const Color(0xFF60A5FA)),
                const SizedBox(width: 8),
                _buildPosChip(3, 'MIDs', const Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                _buildPosChip(4, 'FWDs', const Color(0xFFF97316)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosChip(int posId, String label, [Color? color]) {
    final isSelected = _selectedPosition == posId;
    final activeColor = color ?? AppColors.of(context).primary;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedPosition = posId;
        _visibleCount = 20;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withAlpha(35)
              : AppColors.of(context).cardMedium,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.of(context).divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? activeColor
                : AppColors.of(context).textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Player Card ────────────────────────────────────────────────────────────

  Widget _buildPlayerCard(
    BuildContext context,
    FplProvider provider,
    Player player,
    int count,
    int rank,
  ) {
    final team = provider.getTeamById(player.teamId);
    final posColor = getPositionColor(player.elementType);
    final posName = getPositionShort(player.elementType);

    Color transferColor;
    String transferPrefix;
    if (_currentTab == TransferTab.transfersIn) {
      transferColor = AppColors.of(context).primary;
      transferPrefix = '+';
    } else if (_currentTab == TransferTab.transfersOut) {
      transferColor = AppColors.of(context).error;
      transferPrefix = '-';
    } else {
      if (count > 0) {
        transferColor = AppColors.of(context).primary;
        transferPrefix = '+';
      } else if (count < 0) {
        transferColor = AppColors.of(context).error;
        transferPrefix = '';
      } else {
        transferColor = AppColors.of(context).textSecondary;
        transferPrefix = '';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerDetailScreen(player: player),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: AppTheme.gradientCard(context: context),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              // Player Photo with position tag
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.of(context).cardMedium,
                      border: Border.all(color: posColor.withAlpha(80)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: player.photoUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorWidget: (_, _, _) => Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: posColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        posName,
                        style: const TextStyle(
                          color: Color(0xFF0C0720),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.webName,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          team?.shortName ?? '',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.of(context).textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatPrice(player.nowCost),
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.of(context).textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${player.selectedByPercent}% own',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Transfer Count Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: transferColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: transferColor.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$transferPrefix${_formatCount(count.abs())}',
                      style: TextStyle(
                        color: transferColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _currentTab == TransferTab.transfersIn
                          ? 'IN'
                          : (_currentTab == TransferTab.transfersOut
                              ? 'OUT'
                              : 'NET'),
                      style: TextStyle(
                        color: transferColor.withAlpha(200),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  String _formatCount(int val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(2)}M';
    }
    if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return '$val';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            color: AppColors.of(context).textSecondary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No transfer activity found',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or position filter',
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.of(context).divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => setState(() => _visibleCount += 20),
        child: const Text('Show More Players'),
      ),
    );
  }
}
