import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fpl_provider.dart';
import '../models/team.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';

class FixtureDifficultyScreen extends StatelessWidget {
  const FixtureDifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Fixture Difficulty Ratings'),
            backgroundColor: AppColors.secondary,
          ),
          body: provider.isLoading
              ? const LoadingWidget(height: 300)
              : _buildFDRMatrix(context, provider),
        );
      },
    );
  }

  Widget _buildFDRMatrix(BuildContext context, FplProvider provider) {
    final currentGwId = provider.currentGameweek?.id ?? 1;
    final nextGws = List.generate(5, (i) => currentGwId + i).where((gw) => gw <= 38).toList();

    return Column(
      children: [
        _buildLegend(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(nextGws),
                    const SizedBox(height: 4),
                    ...provider.teams.map((team) => _buildTeamRow(team, nextGws, provider)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardDark,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Difficulty: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ...DifficultyConstants.colors.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: e.value, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${e.key} - ${DifficultyConstants.labels[e.key]}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<int> gws) {
    return Row(
      children: [
        const SizedBox(
          width: 72,
          child: Text('Team', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        ...gws.map((gw) => SizedBox(
              width: 90,
              child: Text(
                'GW$gw',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            )),
      ],
    );
  }

  Widget _buildTeamRow(Team team, List<int> gws, FplProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              team.shortName,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...gws.map((gw) {
            final gwFixtures = provider.fixtures
                .where((f) => f.event == gw && (f.homeTeamId == team.id || f.awayTeamId == team.id))
                .toList();

            if (gwFixtures.isEmpty) {
              return SizedBox(
                width: 90,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cardMedium,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text('-', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                ),
              );
            }

            return SizedBox(
              width: 90,
              child: Column(
                children: gwFixtures.map((f) {
                  final isHome = f.homeTeamId == team.id;
                  final difficulty = isHome ? f.teamHDifficulty : f.teamADifficulty;
                  final opponentId = isHome ? f.awayTeamId : f.homeTeamId;
                  final opponent = provider.getTeamById(opponentId);
                  final diffColor = DifficultyConstants.colors[difficulty] ?? Colors.grey;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: diffColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: diffColor.withAlpha(153)),
                    ),
                    child: Center(
                      child: Text(
                        '${opponent?.shortName ?? '?'} (${isHome ? 'H' : 'A'})',
                        style: TextStyle(
                          color: diffColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
