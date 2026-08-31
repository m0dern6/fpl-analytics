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

        // Calculate predicted price change threshold for each player
        final playersWithVelocity = provider.players.map((p) {
          final netTransfers = p.transfersInEvent - p.transfersOutEvent;
          final ownership = double.tryParse(p.selectedByPercent) ?? 1.0;
          // Target formula: net transfer delta relative to ownership and dynamic base threshold
          final targetBase = (ownership * 4500).clamp(6000.0, 120000.0);
          final progress = ((netTransfers / targetBase) * 100).clamp(-100.0, 100.0);
          return _PlayerPricePrediction(player: p, netTransfers: netTransfers, progress: progress);
        }).toList();

        // Sort by progress / urgency
        List<_PlayerPricePrediction> filtered;
        if (_filter == _PriceFilter.risers) {
          filtered = playersWithVelocity.where((e) => e.progress > 0).toList()
            ..sort((a, b) => b.progress.compareTo(a.progress));
        } else if (_filter == _PriceFilter.fallers) {
          filtered = playersWithVelocity.where((e) => e.progress < 0).toList()
            ..sort((a, b) => a.progress.compareTo(b.progress));
        } else {
          filtered = playersWithVelocity
            ..sort((a, b) => b.progress.abs().compareTo(a.progress.abs()));
        }

        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase().trim();
          filtered = filtered
              .where((e) =>
                  e.player.webName.toLowerCase().contains(q) ||
                  e.player.firstName.toLowerCase().contains(q) ||
                  e.player.secondName.toLowerCase().contains(q))
              .toList();
        }

        final topRiser = playersWithVelocity
            .where((e) => e.progress > 0)
            .toList()
          ..sort((a, b) => b.progress.compareTo(a.progress));
        final topFaller = playersWithVelocity
            .where((e) => e.progress < 0)
            .toList()
          ..sort((a, b) => a.progress.compareTo(b.progress));

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Price Change Predictor'),
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
                  'GW$currentGw Radar',
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
              // Top highlights row (Top Riser & Top Faller)
              if (_searchQuery.isEmpty)
                _buildHighlights(
                  context,
                  topRiser.firstOrNull,
                  topFaller.firstOrNull,
                ),

              // Filter Tabs & Search
              _buildFilterSection(context),

              // Players List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No players matching current criteria',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.take(50).length,
                        itemBuilder: (ctx, i) {
                          return _buildPredictionCard(
                            context,
                            provider,
                            filtered[i],
                            i + 1,
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

  // ── Highlights Banner ──────────────────────────────────────────────────────

  Widget _buildHighlights(
    BuildContext context,
    _PlayerPricePrediction? topRiser,
    _PlayerPricePrediction? topFaller,
  ) {
    if (topRiser == null && topFaller == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riserColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF059669);
    final fallerColor = isDark ? const Color(0xFFF43F5E) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          if (topRiser != null)
            Expanded(
              child: _highlightMiniCard(
                context,
                title: 'Most Likely Rise',
                player: topRiser.player,
                progress: topRiser.progress,
                color: riserColor,
                icon: Icons.trending_up_rounded,
                isRise: true,
              ),
            ),
          if (topRiser != null && topFaller != null) const SizedBox(width: 10),
          if (topFaller != null)
            Expanded(
              child: _highlightMiniCard(
                context,
                title: 'Most Likely Fall',
                player: topFaller.player,
                progress: topFaller.progress,
                color: fallerColor,
                icon: Icons.trending_down_rounded,
                isRise: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _highlightMiniCard(
    BuildContext context, {
    required String title,
    required Player player,
    required double progress,
    required Color color,
    required IconData icon,
    required bool isRise,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(90)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              player.webName,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${isRise ? '+' : ''}${progress.toStringAsFixed(1)}% to target',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filters & Search ────────────────────────────────────────────────────────

  Widget _buildFilterSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riserColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF059669);
    final fallerColor = isDark ? const Color(0xFFF43F5E) : const Color(0xFFDC2626);
    final allColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                hintText: 'Search player to check price prediction...',
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
                  '📈 Risers (Tonight)',
                  _PriceFilter.risers,
                  riserColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tabButton(
                  '📉 Fallers (Tonight)',
                  _PriceFilter.fallers,
                  fallerColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tabButton(
                  'All Radar',
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
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Prediction Card ────────────────────────────────────────────────────────

  Widget _buildPredictionCard(
    BuildContext context,
    FplProvider provider,
    _PlayerPricePrediction item,
    int rank,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riserColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF059669);
    final fallerColor = isDark ? const Color(0xFFF43F5E) : const Color(0xFFDC2626);

    final player = item.player;
    final team = provider.getTeamById(player.teamId);
    final isRise = item.progress >= 0;
    final color = isRise ? riserColor : fallerColor;
    final posColor = getPositionColor(player.elementType);

    final statusText = item.progress.abs() >= 95
        ? (isRise ? '🚨 Rise Expected Tonight (+£0.1m)' : '🚨 Drop Expected Tonight (-£0.1m)')
        : '${item.progress.abs().toStringAsFixed(1)}% to ${isRise ? 'rise' : 'fall'}';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Photo
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.of(context).cardMedium,
                      border: Border.all(color: posColor.withAlpha(80)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: player.photoUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorWidget: (_, _, _) => const Icon(Icons.person, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.webName,
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${team?.shortName ?? ''} • ${formatPrice(player.nowCost)} • ${player.selectedByPercent}% own',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Target % badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isRise ? '+' : ''}${item.progress.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'TARGET',
                          style: TextStyle(
                            color: color.withAlpha(200),
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (item.progress.abs() / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: AppColors.of(context).cardMedium,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: item.progress.abs() >= 95 ? color : AppColors.of(context).textSecondary,
                      fontSize: 10,
                      fontWeight: item.progress.abs() >= 95 ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Net: ${item.netTransfers > 0 ? '+' : ''}${formatNumber(item.netTransfers)}',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 10,
                    ),
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

class _PlayerPricePrediction {
  final Player player;
  final int netTransfers;
  final double progress;

  _PlayerPricePrediction({
    required this.player,
    required this.netTransfers,
    required this.progress,
  });
}
