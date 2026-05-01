import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../widgets/player_card.dart';
import '../widgets/loading_widget.dart';
import 'player_detail_screen.dart';

enum SortOption { points, form, price, ict, selected, value }

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _searchController = TextEditingController();
  int _selectedPosition = 0; // 0 = all
  int _selectedTeam = 0; // 0 = all teams
  SortOption _sortOption = SortOption.points;
  bool _sortAscending = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Player> _filteredAndSorted(List<Player> players) {
    var list = players.where((p) {
      final matchesPos =
          _selectedPosition == 0 || p.elementType == _selectedPosition;
      final matchesTeam = _selectedTeam == 0 || p.teamId == _selectedTeam;
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.webName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.firstName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.secondName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesPos && matchesTeam && matchesSearch;
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortOption) {
        case SortOption.points:
          cmp = a.totalPoints.compareTo(b.totalPoints);
          break;
        case SortOption.form:
          cmp = a.formValue.compareTo(b.formValue);
          break;
        case SortOption.price:
          cmp = a.nowCost.compareTo(b.nowCost);
          break;
        case SortOption.ict:
          cmp = a.ictValue.compareTo(b.ictValue);
          break;
        case SortOption.selected:
          cmp = a.selectedPercent.compareTo(b.selectedPercent);
          break;
        case SortOption.value:
          cmp = a.valueSeasonValue.compareTo(b.valueSeasonValue);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final filtered = _filteredAndSorted(provider.players);
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Players'),
            backgroundColor: AppColors.of(context).secondary,
            actions: [
              PopupMenuButton<SortOption>(
                icon: Icon(
                  Icons.sort_rounded,
                  color: AppColors.of(context).textPrimary,
                ),
                color: AppColors.of(context).cardDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (opt) => setState(() {
                  if (_sortOption == opt) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortOption = opt;
                    _sortAscending = false;
                  }
                }),
                itemBuilder: (_) => [
                  _sortItem(
                    SortOption.points,
                    'Total Points',
                    Icons.star_rounded,
                  ),
                  _sortItem(SortOption.form, 'Form', Icons.trending_up_rounded),
                  _sortItem(
                    SortOption.price,
                    'Price',
                    Icons.attach_money_rounded,
                  ),
                  _sortItem(
                    SortOption.ict,
                    'ICT Index',
                    Icons.analytics_rounded,
                  ),
                  _sortItem(
                    SortOption.selected,
                    'Selected %',
                    Icons.people_rounded,
                  ),
                  _sortItem(SortOption.value, 'Value', Icons.savings_rounded),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSearchBar(),
              _buildFilterChips(provider),
              Expanded(
                child: provider.isLoading
                    ? const LoadingListWidget()
                    : RefreshIndicator(
                        color: AppColors.of(context).primary,
                        backgroundColor: AppColors.of(context).cardDark,
                        onRefresh: provider.refresh,
                        child: filtered.isEmpty
                            ? _buildEmpty()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  16,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (ctx, i) {
                                  final player = filtered[i];
                                  final team = provider.getTeamById(
                                    player.teamId,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: PlayerCard(
                                      player: player,
                                      team: team,
                                      onTap: () => Navigator.push(
                                        ctx,
                                        MaterialPageRoute(
                                          builder: (_) => PlayerDetailScreen(
                                            player: player,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<SortOption> _sortItem(
    SortOption opt,
    String label,
    IconData icon,
  ) {
    final isSelected = _sortOption == opt;
    return PopupMenuItem(
      value: opt,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.of(context).primary : AppColors.of(context).textPrimary,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: AppColors.of(context).primary,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search players…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.of(context).textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips(FplProvider provider) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        children: [
          _positionChip(0, 'All'),
          _positionChip(1, 'GK'),
          _positionChip(2, 'DEF'),
          _positionChip(3, 'MID'),
          _positionChip(4, 'FWD'),
          const SizedBox(width: 8),
          if (provider.teams.isNotEmpty)
            PopupMenuButton<int>(
              color: AppColors.of(context).cardDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (id) => setState(() => _selectedTeam = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _selectedTeam != 0
                      ? AppColors.of(context).primary.withAlpha(28)
                      : AppColors.of(context).cardMedium,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _selectedTeam != 0
                        ? AppColors.of(context).primary.withAlpha(160)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedTeam != 0) ...[
                      CachedNetworkImage(
                        imageUrl:
                            provider.getTeamById(_selectedTeam)?.badgeUrl ?? '',
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            const SizedBox(width: 16, height: 16),
                        errorWidget: (_, __, ___) =>
                            const SizedBox(width: 16, height: 16),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _selectedTeam != 0
                          ? (provider.getTeamById(_selectedTeam)?.shortName ??
                                'Team')
                          : 'All Teams',
                      style: TextStyle(
                        color: _selectedTeam != 0
                            ? AppColors.of(context).primary
                            : AppColors.of(context).textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _selectedTeam != 0
                          ? AppColors.of(context).primary
                          : AppColors.of(context).textSecondary,
                      size: 14,
                    ),
                  ],
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(Icons.groups_rounded,
                          color: AppColors.of(context).textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'All Teams',
                        style: TextStyle(
                          color: _selectedTeam == 0
                              ? AppColors.of(context).primary
                              : AppColors.of(context).textPrimary,
                          fontWeight: _selectedTeam == 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                ...provider.teams.map(
                  (t) => PopupMenuItem(
                    value: t.id,
                    child: Row(
                      children: [
                        CachedNetworkImage(
                          imageUrl: t.badgeUrl,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          placeholder: (_, __) =>
                              const SizedBox(width: 20, height: 20),
                          errorWidget: (_, __, ___) =>
                              const SizedBox(width: 20, height: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.name,
                          style: TextStyle(
                            color: _selectedTeam == t.id
                                ? AppColors.of(context).primary
                                : AppColors.of(context).textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _positionChip(int pos, String label) {
    final isSelected = _selectedPosition == pos;
    Color? chipColor;
    if (pos > 0) chipColor = PositionConstants.positionColors[pos];
    final color = chipColor ?? AppColors.of(context).primary;
    return GestureDetector(
      onTap: () => setState(() => _selectedPosition = pos),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(28) : AppColors.of(context).cardMedium,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color.withAlpha(160) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.of(context).textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: AppColors.of(context).textSecondary, size: 48),
          SizedBox(height: 12),
          Text(
            'No players found',
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ],
      ),
    );
  }
}
