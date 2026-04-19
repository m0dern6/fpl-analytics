import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import 'player_detail_screen.dart';

class BestTeamScreen extends StatefulWidget {
  const BestTeamScreen({super.key});

  @override
  State<BestTeamScreen> createState() => _BestTeamScreenState();
}

class _BestTeamScreenState extends State<BestTeamScreen> {
  String _formation = '4-3-3';

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Best Team'),
            backgroundColor: AppColors.secondary,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune, color: AppColors.textPrimary),
                color: AppColors.cardDark,
                onSelected: (f) => setState(() => _formation = f),
                itemBuilder: (_) => ['4-3-3', '4-4-2', '3-5-2', '5-3-2', '3-4-3']
                    .map((f) => PopupMenuItem(
                          value: f,
                          child: Text(
                            f,
                            style: TextStyle(color: _formation == f ? AppColors.primary : AppColors.textPrimary),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          body: provider.isLoading
              ? const LoadingListWidget()
              : _buildBody(context, provider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FplProvider provider) {
    if (provider.players.isEmpty) {
      return const Center(child: Text('No data available', style: TextStyle(color: AppColors.textSecondary)));
    }

    final bestTeam = provider.getBestTeam();
    final starting = bestTeam['starting'] ?? <Player>[];
    final subs = bestTeam['subs'] ?? <Player>[];
    final all = bestTeam['all'] ?? <Player>[];
    final totalCost = all.fold<int>(0, (sum, p) => sum + p.nowCost);
    final totalPts = starting.fold<int>(0, (sum, p) => sum + p.totalPoints);

    final formationParts = _formation.split('-').map(int.parse).toList();
    final defCount = formationParts[0];
    final midCount = formationParts[1];
    final fwdCount = formationParts[2];

    final gks = starting.where((p) => p.elementType == 1).toList();
    final defs = starting.where((p) => p.elementType == 2).take(defCount).toList();
    final mids = starting.where((p) => p.elementType == 3).take(midCount).toList();
    final fwds = starting.where((p) => p.elementType == 4).take(fwdCount).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStats(totalCost, totalPts, _formation),
          _buildPitch(context, gks, defs, mids, fwds, provider),
          _buildSubsSection(context, subs, provider),
          _buildSelectionCriteria(),
          _buildChipAdvice(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStats(int totalCost, int totalPts, String formation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.purpleGradient(borderRadius: BorderRadius.zero),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('Formation', formation, Icons.grid_3x3),
          _statItem('Total Cost', formatPrice(totalCost), Icons.attach_money),
          _statItem('Total Pts', '$totalPts', Icons.star),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildPitch(BuildContext context, List<Player> gks, List<Player> defs, List<Player> mids, List<Player> fwds, FplProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a4a1a), Color(0xFF0d2d0d)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildPitchRow(context, fwds, provider, PositionConstants.positionColors[4]!),
          const SizedBox(height: 12),
          _buildPitchRow(context, mids, provider, PositionConstants.positionColors[3]!),
          const SizedBox(height: 12),
          _buildPitchRow(context, defs, provider, PositionConstants.positionColors[2]!),
          const SizedBox(height: 12),
          _buildPitchRow(context, gks, provider, PositionConstants.positionColors[1]!),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPitchRow(BuildContext context, List<Player> players, FplProvider provider, Color posColor) {
    if (players.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: players.map((p) {
            final diff = provider.getNextFixtureDifficulty(p.teamId);
            return SizedBox(
              width: (constraints.maxWidth / players.length).clamp(60.0, 80.0),
              child: _PitchPlayer(
                player: p,
                posColor: posColor,
                nextFixtureDifficulty: diff,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: p)));
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSubsSection(BuildContext context, List<Player> subs, FplProvider provider) {
    if (subs.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.textSecondary, size: 16),
              SizedBox(width: 6),
              Text('Substitutes', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: subs.take(4).map((p) {
                  final diff = provider.getNextFixtureDifficulty(p.teamId);
                  return SizedBox(
                    width: (constraints.maxWidth / 4).clamp(60.0, 80.0),
                    child: _PitchPlayer(
                      player: p,
                      posColor: getPositionColor(p.elementType),
                      isSub: true,
                      nextFixtureDifficulty: diff,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: p))),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCriteria() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text('Smart Selection Algorithm', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Players selected using a composite score based on:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _criteriaChip('📈 Recent Form', AppColors.primary),
              _criteriaChip('⚡ ICT Index', AppColors.warning),
              _criteriaChip('🎯 Points/Game', AppColors.accent),
              _criteriaChip('💰 Value', const Color(0xFF69F0AE)),
              _criteriaChip('🏟 Fixture Difficulty', const Color(0xFFB388FF)),
              _criteriaChip('🩺 Availability', AppColors.error),
              _criteriaChip('🔄 Transfer Momentum', AppColors.textSecondary),
              _criteriaChip('👥 Max 3/Club', AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _criteriaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildChipAdvice() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chip Advice', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _chipItem('Triple Captain', 'Use on your highest scoring GW captain', Icons.star, AppColors.warning),
          const SizedBox(height: 8),
          _chipItem('Bench Boost', 'Use when all 15 players have good fixtures', Icons.people, AppColors.primary),
          const SizedBox(height: 8),
          _chipItem('Free Hit', 'Use in a blank or double gameweek', Icons.refresh, AppColors.accent),
          const SizedBox(height: 8),
          _chipItem('Wildcard', 'Use to completely rebuild your squad', Icons.shuffle, const Color(0xFFB388FF)),
        ],
      ),
    );
  }

  Widget _chipItem(String name, String advice, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(advice, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PitchPlayer extends StatelessWidget {
  final Player player;
  final Color posColor;
  final bool isSub;
  final VoidCallback? onTap;
  final int? nextFixtureDifficulty;

  const _PitchPlayer({
    required this.player,
    required this.posColor,
    this.isSub = false,
    this.onTap,
    this.nextFixtureDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = nextFixtureDifficulty != null
        ? (DifficultyConstants.colors[nextFixtureDifficulty] ?? AppColors.textSecondary)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: isSub ? 48 : 56,
                  height: isSub ? 48 : 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardDark,
                    border: Border.all(color: posColor, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: player.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Icon(Icons.person, color: AppColors.textSecondary, size: isSub ? 24 : 28),
                    errorWidget: (_, __, ___) => Icon(Icons.person, color: AppColors.textSecondary, size: isSub ? 24 : 28),
                  ),
                ),
                if (diffColor != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: diffColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardDark, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.webName.length > 9 ? player.webName.substring(0, 8) : player.webName,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(204),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                player.form,
                style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
