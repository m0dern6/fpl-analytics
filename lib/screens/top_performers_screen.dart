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

class TopPerformersScreen extends StatefulWidget {
  final int? initialGameweek;

  const TopPerformersScreen({super.key, this.initialGameweek});

  @override
  State<TopPerformersScreen> createState() => _TopPerformersScreenState();
}

class _TopPerformersScreenState extends State<TopPerformersScreen> {
  int? _selectedGw; // null means Season Overall
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
    _selectedGw = widget.initialGameweek ?? currentGw;

    if (_selectedGw != null) {
      _loadGwData(_selectedGw!);
    }
  }

  void _loadGwData(int gw) {
    final provider = context.read<FplProvider>();
    provider.loadLiveGwData(gw);
    provider.loadDreamTeam(gw);
  }

  @override
  void dispose() {
    _gwScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToCurrentGw(int currentGw) {
    if (_didAutoScroll) return;
    _didAutoScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gwScrollController.hasClients) return;
      // Each pill is ~76px wide, center target
      final targetOffset = ((currentGw) * 78.0) - 120.0;
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
        _scrollToCurrentGw(currentGw);

        final isSeason = _selectedGw == null;
        final isCurrentGwSelected = _selectedGw == currentGw;

        // Fetch and sort players
        List<MapEntry<Player, int>> playerPointsList;

        if (isSeason) {
          playerPointsList = provider.players
              .map((p) => MapEntry(p, p.totalPoints))
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));
        } else {
          final gw = _selectedGw!;
          playerPointsList = provider.players
              .map((p) {
                final pts = provider.getPlayerPointsForGameweek(p.id, gw);
                return MapEntry(p, pts);
              })
              .where((entry) => entry.value > 0 || isCurrentGwSelected)
              .toList()
            ..sort((a, b) {
              final ptsComp = b.value.compareTo(a.value);
              if (ptsComp != 0) return ptsComp;
              return b.key.totalPoints.compareTo(a.key.totalPoints);
            });
        }

        // Apply position filter
        if (_selectedPosition > 0) {
          playerPointsList = playerPointsList
              .where((e) => e.key.elementType == _selectedPosition)
              .toList();
        }

        // Apply search filter
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase().trim();
          playerPointsList = playerPointsList
              .where((e) =>
                  e.key.webName.toLowerCase().contains(q) ||
                  e.key.firstName.toLowerCase().contains(q) ||
                  e.key.secondName.toLowerCase().contains(q))
              .toList();
        }

        final visibleList = playerPointsList.take(_visibleCount).toList();
        final canShowMore = _visibleCount < playerPointsList.length;

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Top Performers'),
            backgroundColor: AppColors.of(context).secondary,
            actions: [
              if (!isSeason)
                IconButton(
                  tooltip: 'Refresh GW Data',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _loadGwData(_selectedGw!),
                ),
            ],
          ),
          body: Column(
            children: [
              _buildGameweekSelector(context, provider, currentGw),
              _buildFilterHeader(context, playerPointsList.length),
              Expanded(
                child: visibleList.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visibleList.length + (canShowMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == visibleList.length) {
                            return _buildShowMoreButton();
                          }
                          final entry = visibleList[index];
                          return _buildPlayerCard(
                            context,
                            provider,
                            entry.key,
                            entry.value,
                            index + 1,
                            isSeason,
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

  Widget _buildGameweekSelector(
    BuildContext context,
    FplProvider provider,
    int currentGwId,
  ) {
    return Container(
      color: AppColors.of(context).secondary,
      padding: const EdgeInsets.symmetric(vertical: 10),
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
              isCurrent: false,
              onTap: () => setState(() {
                _selectedGw = null;
                _visibleCount = 20;
              }),
            ),
            const SizedBox(width: 8),
            // GW 1 to GW 38 Pills
            ...List.generate(_totalGws, (i) {
              final gwId = i + 1;
              final isCurrent = gwId == currentGwId;
              final isSelected = _selectedGw == gwId;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildGwPill(
                  context,
                  label: 'GW$gwId',
                  isSelected: isSelected,
                  isCurrent: isCurrent,
                  onTap: () {
                    setState(() {
                      _selectedGw = gwId;
                      _visibleCount = 20;
                    });
                    _loadGwData(gwId);
                  },
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
    required bool isCurrent,
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
              : (isCurrent
                  ? primaryColor.withAlpha(24)
                  : AppColors.of(context).cardMedium),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isCurrent ? primaryColor : AppColors.of(context).divider),
            width: isCurrent || isSelected ? 1.5 : 1,
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
                    : (isCurrent
                        ? primaryColor
                        : AppColors.of(context).textPrimary),
                fontSize: 12,
                fontWeight: isSelected || isCurrent
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 5),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0C0720)
                      : primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Filters & Search ────────────────────────────────────────────────────────

  Widget _buildFilterHeader(BuildContext context, int totalCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        children: [
          // Search box
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
          // Position filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPosChip(0, 'All'),
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
    int points,
    int rank,
    bool isSeason,
  ) {
    final team = provider.getTeamById(player.teamId);
    final posColor = getPositionColor(player.elementType);
    final posName = getPositionShort(player.elementType);

    // Rank Medal / Badge
    Widget rankWidget;
    if (rank == 1) {
      rankWidget = _rankBadge(context, '🥇', const Color(0xFFFFD700), '1');
    } else if (rank == 2) {
      rankWidget = _rankBadge(context, '🥈', const Color(0xFFC0C0C0), '2');
    } else if (rank == 3) {
      rankWidget = _rankBadge(context, '🥉', const Color(0xFFCD7F32), '3');
    } else {
      rankWidget = SizedBox(
        width: 26,
        child: Text(
          '$rank',
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      );
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
              rankWidget,
              const SizedBox(width: 8),
              // Player Photo with team badge
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
                      placeholder: (_, _) => Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 22,
                      ),
                      errorWidget: (_, _, _) => Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 22,
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
                        if (isSeason) ...[
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
                            'Form ${formatForm(player.form)}',
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Points Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: points >= 10
                      ? AppColors.of(context).primary.withAlpha(30)
                      : (points >= 6
                          ? const Color(0xFF34D399).withAlpha(20)
                          : AppColors.of(context).cardMedium),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: points >= 10
                        ? AppColors.of(context).primary
                        : (points >= 6
                            ? const Color(0xFF34D399).withAlpha(90)
                            : AppColors.of(context).divider),
                    width: points >= 10 ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$points',
                      style: TextStyle(
                        color: points >= 10
                            ? AppColors.of(context).primary
                            : (points >= 6
                                ? const Color(0xFF34D399)
                                : AppColors.of(context).textPrimary),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'PTS',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
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

  Widget _rankBadge(
    BuildContext context,
    String medal,
    Color color,
    String rankStr,
  ) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
      ),
      child: Center(
        child: Text(
          rankStr,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: AppColors.of(context).textSecondary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No performers found',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try selecting another gameweek or filter',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => setState(() => _visibleCount += 20),
        child: const Text('Show More Players'),
      ),
    );
  }
}
