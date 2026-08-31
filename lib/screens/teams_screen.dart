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
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Teams'),
            backgroundColor: AppColors.of(context).secondary,
          ),
          body: provider.isLoading
              ? const LoadingGridWidget(itemCount: 20)
              : RefreshIndicator(
                  color: AppColors.of(context).primary,
                  backgroundColor: AppColors.of(context).cardDark,
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
        decoration: AppTheme.gradientCard(context: context, ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: team.badgeUrl,
              height: 50,
              width: 50,
              placeholder: (_, _) => Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.of(context).cardMedium,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield, color: AppColors.of(context).textSecondary),
              ),
              errorWidget: (_, _, _) => Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.of(context).cardMedium,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    team.shortName,
                    style: TextStyle(
                      color: AppColors.of(context).primary,
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
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              team.name,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _strengthDot(context, team.strengthOverallHome, 'H'),
                const SizedBox(width: 4),
                _strengthDot(context, team.strengthOverallAway, 'A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _strengthDot(BuildContext context, int strength, String label) {
    final color = strength >= 1300
        ? AppColors.of(context).primary
        : strength >= 1200
        ? AppColors.of(context).accent
        : strength >= 1100
        ? AppColors.of(context).warning
        : AppColors.of(context).error;
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
          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 9),
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
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: Text(team.name),
            backgroundColor: AppColors.of(context).secondary,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamHeader(context),
                const SizedBox(height: 16),
                _buildStrengthSection(context),
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Squad'),
                const SizedBox(height: 12),
                _buildSquadByPosition(context, teamPlayers, provider),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildSectionTitle(context, 'Recent Fixtures')),
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

  Widget _buildTeamHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.purpleGradient(),
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: team.badgeUrl,
            height: 70,
            width: 70,
            errorWidget: (_, _, _) => Container(
              width: 70,
              height: 70,
              color: AppColors.of(context).cardMedium,
              child: Center(
                child: Text(
                  team.shortName,
                  style: TextStyle(
                    color: AppColors.of(context).primary,
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
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Strength: ${team.strength}',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context, ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Strength',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _strengthBar(context, 'Overall Home', team.strengthOverallHome, 1400),
          const SizedBox(height: 8),
          _strengthBar(context, 'Overall Away', team.strengthOverallAway, 1400),
          const SizedBox(height: 8),
          _strengthBar(context, 'Attack Home', team.strengthAttackHome, 1400),
          const SizedBox(height: 8),
          _strengthBar(context, 'Attack Away', team.strengthAttackAway, 1400),
          const SizedBox(height: 8),
          _strengthBar(context, 'Defence Home', team.strengthDefenceHome, 1400),
          const SizedBox(height: 8),
          _strengthBar(context, 'Defence Away', team.strengthDefenceAway, 1400),
        ],
      ),
    );
  }

  Widget _strengthBar(BuildContext context, String label, int value, int max) {
    final pct = (value / max).clamp(0.0, 1.0);
    final color = value >= 1300
        ? AppColors.of(context).primary
        : value >= 1200
        ? AppColors.of(context).accent
        : value >= 1100
        ? AppColors.of(context).warning
        : AppColors.of(context).error;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
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
                  color: AppColors.of(context).cardMedium,
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.of(context).primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
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
                  decoration: AppTheme.gradientCard(context: context, ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.webName,
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        formatPrice(p.nowCost),
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${p.totalPoints} pts',
                        style: TextStyle(
                          color: AppColors.of(context).primary,
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
    if (completed.isEmpty) {
      return Text(
        'No completed fixtures',
        style: TextStyle(color: AppColors.of(context).textSecondary),
      );
    }

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
            decoration: AppTheme.gradientCard(context: context, ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    home?.shortName ?? '?',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
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
                    color: AppColors.of(context).cardMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${f.homeTeamScore} - ${f.awayTeamScore}',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    away?.shortName ?? '?',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
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
