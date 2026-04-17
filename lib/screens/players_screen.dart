import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
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
  int? _selectedTeam;
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
      final matchesPos = _selectedPosition == 0 || p.elementType == _selectedPosition;
      final matchesTeam = _selectedTeam == null || p.teamId == _selectedTeam;
      final matchesSearch = _searchQuery.isEmpty ||
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
        case SortOption.form:
          cmp = a.formValue.compareTo(b.formValue);
        case SortOption.price:
          cmp = a.nowCost.compareTo(b.nowCost);
        case SortOption.ict:
          cmp = a.ictValue.compareTo(b.ictValue);
        case SortOption.selected:
          cmp = a.selectedPercent.compareTo(b.selectedPercent);
        case SortOption.value:
          cmp = a.valueSeasonValue.compareTo(b.valueSeasonValue);
        default:
          cmp = 0;
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Players'),
            backgroundColor: AppColors.secondary,
            actions: [
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort, color: AppColors.textPrimary),
                color: AppColors.cardDark,
                onSelected: (opt) => setState(() {
                  if (_sortOption == opt) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortOption = opt;
                    _sortAscending = false;
                  }
                }),
                itemBuilder: (_) => [
                  _sortItem(SortOption.points, 'Total Points', Icons.star),
                  _sortItem(SortOption.form, 'Form', Icons.trending_up),
                  _sortItem(SortOption.price, 'Price', Icons.attach_money),
                  _sortItem(SortOption.ict, 'ICT Index', Icons.analytics),
                  _sortItem(SortOption.selected, 'Selected %', Icons.people),
                  _sortItem(SortOption.value, 'Value', Icons.savings),
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
                        color: AppColors.primary,
                        backgroundColor: AppColors.cardDark,
                        onRefresh: provider.refresh,
                        child: filtered.isEmpty
                            ? _buildEmpty()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: filtered.length,
                                itemBuilder: (ctx, i) {
                                  final player = filtered[i];
                                  final team = provider.getTeamById(player.teamId);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: PlayerCard(
                                      player: player,
                                      team: team,
                                      onTap: () => Navigator.push(
                                        ctx,
                                        MaterialPageRoute(
                                          builder: (_) => PlayerDetailScreen(player: player),
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

  PopupMenuItem<SortOption> _sortItem(SortOption opt, String label, IconData icon) {
    final isSelected = _sortOption == opt;
    return PopupMenuItem(
      value: opt,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary)),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: AppColors.primary,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search players...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
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
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _positionChip(0, 'All'),
          _positionChip(1, 'GK'),
          _positionChip(2, 'DEF'),
          _positionChip(3, 'MID'),
          _positionChip(4, 'FWD'),
          const SizedBox(width: 8),
          if (provider.teams.isNotEmpty)
            PopupMenuButton<int?>(
              color: AppColors.cardDark,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTeam != null ? AppColors.primary.withAlpha(51) : AppColors.cardMedium,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedTeam != null ? AppColors.primary : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedTeam != null
                          ? (provider.getTeamById(_selectedTeam!)?.shortName ?? 'Team')
                          : 'Team ▾',
                      style: TextStyle(
                        color: _selectedTeam != null ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              onSelected: (id) => setState(() => _selectedTeam = id),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: null,
                  child: Text('All Teams', style: TextStyle(color: _selectedTeam == null ? AppColors.primary : AppColors.textPrimary)),
                ),
                ...provider.teams.map(
                  (t) => PopupMenuItem(
                    value: t.id,
                    child: Text(t.name, style: TextStyle(color: _selectedTeam == t.id ? AppColors.primary : AppColors.textPrimary)),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedPosition = pos),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (chipColor ?? AppColors.primary).withAlpha(51)
              : AppColors.cardMedium,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (chipColor ?? AppColors.primary) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (chipColor ?? AppColors.primary) : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: AppColors.textSecondary, size: 48),
          SizedBox(height: 12),
          Text('No players found', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
