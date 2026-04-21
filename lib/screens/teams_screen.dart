import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/fixture.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import 'fixture_detail_screen.dart';
import 'player_detail_screen.dart';
import 'team_fixtures_screen.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Teams'),
            backgroundColor: AppColors.secondary,
          ),
          body: provider.isLoading
              ? const LoadingGridWidget(itemCount: 20)
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardDark,
                  onRefresh: provider.refresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                    itemCount: provider.teams.length,
                    itemBuilder: (ctx, i) {
                      final team = provider.teams[i];
                      return _TeamCard(team: team);
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.gradientCard(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: team.badgeUrl,
              height: 50,
              width: 50,
              placeholder: (_, __) => Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.cardMedium,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield, color: AppColors.textSecondary),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.cardMedium,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    team.shortName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              team.shortName,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              team.name,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _strengthDot(team.strengthOverallHome, 'H'),
                const SizedBox(width: 4),
                _strengthDot(team.strengthOverallAway, 'A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _strengthDot(int strength, String label) {
    final color = strength >= 1300
        ? AppColors.primary
        : strength >= 1200
        ? AppColors.accent
        : strength >= 1100
        ? AppColors.warning
        : AppColors.error;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        ),
      ],
    );
  }
}

class TeamDetailScreen extends StatelessWidget {
  final Team team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final teamPlayers =
            provider.players.where((p) => p.teamId == team.id).toList()
              ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

        final teamFixtures = provider.getFixturesForTeam(team.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(team.name),
            backgroundColor: AppColors.secondary,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamHeader(),
                const SizedBox(height: 16),
                _buildStrengthSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Squad'),
                const SizedBox(height: 12),
                _buildSquadByPosition(context, teamPlayers, provider),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildSectionTitle('Recent Fixtures')),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeamFixturesScreen(team: team),
                        ),
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFixtures(context, teamFixtures, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.purpleGradient(),
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: team.badgeUrl,
            height: 70,
            width: 70,
            errorWidget: (_, __, ___) => Container(
              width: 70,
              height: 70,
              color: AppColors.cardMedium,
              child: Center(
                child: Text(
                  team.shortName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Strength: ${team.strength}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Strength',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _strengthBar('Overall Home', team.strengthOverallHome, 1400),
          const SizedBox(height: 8),
          _strengthBar('Overall Away', team.strengthOverallAway, 1400),
          const SizedBox(height: 8),
          _strengthBar('Attack Home', team.strengthAttackHome, 1400),
          const SizedBox(height: 8),
          _strengthBar('Attack Away', team.strengthAttackAway, 1400),
          const SizedBox(height: 8),
          _strengthBar('Defence Home', team.strengthDefenceHome, 1400),
          const SizedBox(height: 8),
          _strengthBar('Defence Away', team.strengthDefenceAway, 1400),
        ],
      ),
    );
  }

  Widget _strengthBar(String label, int value, int max) {
    final pct = (value / max).clamp(0.0, 1.0);
    final color = value >= 1300
        ? AppColors.primary
        : value >= 1200
        ? AppColors.accent
        : value >= 1100
        ? AppColors.warning
        : AppColors.error;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.cardMedium,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSquadByPosition(
    BuildContext context,
    List<Player> players,
    FplProvider provider,
  ) {
    final positions = [1, 2, 3, 4];
    return Column(
      children: positions.map((pos) {
        final posPlayers = players.where((p) => p.elementType == pos).toList();
        if (posPlayers.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                getPositionFull(pos),
                style: TextStyle(
                  color: getPositionColor(pos),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...posPlayers.map(
              (p) => InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerDetailScreen(player: p),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: AppTheme.gradientCard(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.webName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        formatPrice(p.nowCost),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${p.totalPoints} pts',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFixtures(
    BuildContext context,
    List<Fixture> fixtures,
    FplProvider provider,
  ) {
    final recent = List<Fixture>.from(fixtures)
      ..sort((a, b) {
        final aKey = a.kickoffTime ?? '';
        final bKey = b.kickoffTime ?? '';
        return bKey.compareTo(aKey);
      });
    final completed = recent.where((f) => f.finished == true).take(5).toList();
    if (completed.isEmpty)
      return const Text(
        'No completed fixtures',
        style: TextStyle(color: AppColors.textSecondary),
      );

    return Column(
      children: completed.map((f) {
        final home = provider.getTeamById(f.homeTeamId);
        final away = provider.getTeamById(f.awayTeamId);
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FixtureDetailScreen(
                fixture: f,
                homeTeam: home,
                awayTeam: away,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.gradientCard(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    home?.shortName ?? '?',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${f.homeTeamScore} - ${f.awayTeamScore}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    away?.shortName ?? '?',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
