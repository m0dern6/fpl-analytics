import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'player_detail_screen.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  Player? _playerA;
  Player? _playerB;
  final _searchAController = TextEditingController();
  final _searchBController = TextEditingController();
  String _searchAQuery = '';
  String _searchBQuery = '';

  @override
  void dispose() {
    _searchAController.dispose();
    _searchBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Compare Players'),
            backgroundColor: AppColors.secondary,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPlayerSelector(
                        context,
                        provider,
                        _playerA,
                        _searchAController,
                        _searchAQuery,
                        (q) => setState(() => _searchAQuery = q),
                        (p) => setState(() => _playerA = p),
                        'Player A',
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardMedium,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('VS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                    Expanded(
                      child: _buildPlayerSelector(
                        context,
                        provider,
                        _playerB,
                        _searchBController,
                        _searchBQuery,
                        (q) => setState(() => _searchBQuery = q),
                        (p) => setState(() => _playerB = p),
                        'Player B',
                      ),
                    ),
                  ],
                ),
                if (_playerA != null && _playerB != null) ...[
                  const SizedBox(height: 20),
                  _buildComparison(context, provider, _playerA!, _playerB!),
                ] else ...[
                  const SizedBox(height: 40),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.compare_arrows, color: AppColors.textSecondary, size: 64),
                        SizedBox(height: 12),
                        Text('Select two players to compare', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerSelector(
    BuildContext context,
    FplProvider provider,
    Player? selected,
    TextEditingController controller,
    String query,
    Function(String) onQueryChanged,
    Function(Player) onSelected,
    String label,
  ) {
    final results = query.isNotEmpty
        ? provider.searchPlayers(query).take(5).toList()
        : <Player>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected != null)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: selected)),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: AppTheme.gradientCard(),
              child: Column(
                children: [
                  Text(
                    selected.webName,
                    style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    provider.getTeamById(selected.teamId)?.shortName ?? '',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (label == 'Player A') _playerA = null;
                        else _playerB = null;
                      });
                      controller.clear();
                      onQueryChanged('');
                    },
                    child: const Icon(Icons.close, color: AppColors.error, size: 16),
                  ),
                ],
              ),
            ),
          )
        else
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: results.map((p) => InkWell(
                onTap: () {
                  onSelected(p);
                  controller.clear();
                  onQueryChanged('');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(p.webName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text(formatPrice(p.nowCost), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildComparison(BuildContext context, FplProvider provider, Player a, Player b) {
    return Column(
      children: [
        _buildRadarChart(a, b),
        const SizedBox(height: 20),
        _buildStatsTable(provider, a, b),
      ],
    );
  }

  Widget _buildRadarChart(Player a, Player b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ICT Comparison', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(AppColors.primary, a.webName),
              const SizedBox(width: 16),
              _legendDot(AppColors.accent, b.webName),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            ('ICT Index', a.ictValue, b.ictValue, [a.ictValue, b.ictValue].reduce((x, y) => x > y ? x : y)),
            ('Influence', a.influenceValue, b.influenceValue, [a.influenceValue, b.influenceValue].reduce((x, y) => x > y ? x : y)),
            ('Creativity', a.creativityValue, b.creativityValue, [a.creativityValue, b.creativityValue].reduce((x, y) => x > y ? x : y)),
            ('Threat', a.threatValue, b.threatValue, [a.threatValue, b.threatValue].reduce((x, y) => x > y ? x : y)),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _compBar(item.$1, item.$2, item.$3, item.$4),
          )),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }

  Widget _compBar(String label, double valA, double valB, double max) {
    if (max == 0) max = 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(valA.toStringAsFixed(1), style: const TextStyle(color: AppColors.primary, fontSize: 11), textAlign: TextAlign.right),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Container(color: AppColors.cardMedium),
                      FractionallySizedBox(
                        widthFactor: (valA / max).clamp(0.0, 1.0),
                        child: Container(color: AppColors.primary.withAlpha(153)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Container(color: AppColors.cardMedium),
                      FractionallySizedBox(
                        widthFactor: (valB / max).clamp(0.0, 1.0),
                        child: Container(color: AppColors.accent.withAlpha(153)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 40,
              child: Text(valB.toStringAsFixed(1), style: const TextStyle(color: AppColors.accent, fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsTable(FplProvider provider, Player a, Player b) {
    final stats = [
      ('Total Points', '${a.totalPoints}', '${b.totalPoints}'),
      ('Price', formatPrice(a.nowCost), formatPrice(b.nowCost)),
      ('Form', formatForm(a.form), formatForm(b.form)),
      ('Selected %', formatPercent(a.selectedByPercent), formatPercent(b.selectedByPercent)),
      ('Goals', '${a.goals}', '${b.goals}'),
      ('Assists', '${a.assists}', '${b.assists}'),
      ('Clean Sheets', '${a.cleanSheets}', '${b.cleanSheets}'),
      ('Bonus Points', '${a.bonus}', '${b.bonus}'),
      ('Minutes', '${a.minutes}', '${b.minutes}'),
      ('Points/Game', formatDouble(a.pointsPerGame), formatDouble(b.pointsPerGame)),
    ];

    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Text(a.webName, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.left)),
                const SizedBox(width: 80, child: Text('Stat', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text(b.webName, style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...stats.map((s) {
            final (label, valA, valB) = s;
            final numA = double.tryParse(valA.replaceAll(RegExp(r'[£%m]'), '')) ?? 0;
            final numB = double.tryParse(valB.replaceAll(RegExp(r'[£%m]'), '')) ?? 0;
            final aWins = numA > numB;
            final bWins = numB > numA;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valA,
                      style: TextStyle(
                        color: aWins ? AppColors.primary : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: aWins ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text(
                      valB,
                      style: TextStyle(
                        color: bWins ? AppColors.accent : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: bWins ? FontWeight.w700 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.right,
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
