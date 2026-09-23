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

enum _PriceFilter { risers, fallers, all }

class PriceChangesScreen extends StatefulWidget {
  const PriceChangesScreen({super.key});

  @override
  State<PriceChangesScreen> createState() => _PriceChangesScreenState();
}

class _PriceChangesScreenState extends State<PriceChangesScreen> {
  _PriceFilter _filter = _PriceFilter.risers;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final currentGw = provider.currentGameweek?.id ?? 1;

        // Filter players based on actual price changes
        List<Player> filteredPlayers = [];
        if (_filter == _PriceFilter.risers) {
          filteredPlayers = provider.players.where((p) => p.costChangeEvent > 0).toList()
            ..sort((a, b) => b.costChangeEvent.compareTo(a.costChangeEvent));
        } else if (_filter == _PriceFilter.fallers) {
          filteredPlayers = provider.players.where((p) => p.costChangeEvent < 0).toList()
            ..sort((a, b) => a.costChangeEvent.compareTo(b.costChangeEvent)); // most negative first
        } else {
          filteredPlayers = provider.players.where((p) => p.costChangeEvent != 0).toList()
            ..sort((a, b) => b.costChangeEvent.abs().compareTo(a.costChangeEvent.abs()));
        }

        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase().trim();
          filteredPlayers = filteredPlayers
              .where((e) =>
                  e.webName.toLowerCase().contains(q) ||
                  e.firstName.toLowerCase().contains(q) ||
                  e.secondName.toLowerCase().contains(q))
              .toList();
        }

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Price Changes'),
            backgroundColor: AppColors.of(context).secondary,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.of(context).primary.withAlpha(80),
                  ),
                ),
                child: Text(
                  'GW$currentGw',
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter Tabs & Search
              _buildFilterSection(context),

              // Players List
              Expanded(
                child: filteredPlayers.isEmpty
                    ? Center(
                        child: Text(
                          'No price changes found',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredPlayers.length,
                        itemBuilder: (ctx, i) {
                          return _buildPriceCard(
                            context,
                            provider,
                            filteredPlayers[i],
                          ).animate().fadeIn(delay: Duration(milliseconds: (i % 10) * 20));
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Filters & Search ────────────────────────────────────────────────────────

  Widget _buildFilterSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riserColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF059669);
    final fallerColor = isDark ? const Color(0xFFF43F5E) : const Color(0xFFDC2626);
    final allColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search player...',
                hintStyle: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.of(context).textSecondary, size: 18),
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
          // Filter Tabs
          Row(
            children: [
              Expanded(
                child: _tabButton(
                  '📈 Risers',
                  _PriceFilter.risers,
                  riserColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tabButton(
                  '📉 Fallers',
                  _PriceFilter.fallers,
                  fallerColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tabButton(
                  'All Changes',
                  _PriceFilter.all,
                  allColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String title, _PriceFilter filter, Color color) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : AppColors.of(context).cardMedium,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.of(context).divider,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? color : AppColors.of(context).textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Price Card ────────────────────────────────────────────────────────

  Widget _buildPriceCard(
    BuildContext context,
    FplProvider provider,
    Player player,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riserColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF059669);
    final fallerColor = isDark ? const Color(0xFFF43F5E) : const Color(0xFFDC2626);

    final team = provider.getTeamById(player.teamId);
    final isRise = player.costChangeEvent >= 0;
    final color = isRise ? riserColor : fallerColor;
    final posColor = getPositionColor(player.elementType);
    
    // FPL price changes are stored as integers (1 = £0.1m)
    final changeAmount = player.costChangeEvent / 10.0;
    final changeSymbol = isRise ? '+' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.gradientCard(context: context),
          child: Row(
            children: [
              // Photo
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
                  errorWidget: (_, _, _) => const Icon(Icons.person, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.webName,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${team?.shortName ?? ''} • ${player.selectedByPercent}% own',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Price Details
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPrice(player.nowCost),
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRise ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: color,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$changeSymbol£${changeAmount.abs().toStringAsFixed(1)}m',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
