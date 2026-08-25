import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_teams_provider.dart';
import '../providers/fpl_provider.dart';
import '../models/user_team.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'team_builder_screen.dart';

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserTeamsProvider>().loadTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserTeamsProvider, FplProvider>(
      builder: (context, teamsProvider, fplProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('My Teams'),
            backgroundColor: AppColors.of(context).secondary,
          ),
          body: teamsProvider.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.of(context).primary,
                  ),
                )
              : teamsProvider.teams.isEmpty
              ? _buildEmpty(context)
              : _buildTeamList(context, teamsProvider, fplProvider),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.of(context).primary,
            foregroundColor: AppColors.of(context).secondary,
            onPressed: () => _openBuilder(context, null),
            icon: const Icon(Icons.add),
            label: const Text(
              'Create Team',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.of(context).primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_add,
                color: AppColors.of(context).primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Teams Yet',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first FPL team with unlimited\ntransfers and the official £100m budget.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.of(context).primary,
                foregroundColor: AppColors.of(context).secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _openBuilder(context, null),
              icon: const Icon(Icons.add),
              label: const Text(
                'Create First Team',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamList(
    BuildContext context,
    UserTeamsProvider teamsProvider,
    FplProvider fplProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: teamsProvider.teams.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _TeamCard(
          team: teamsProvider.teams[i],
          fplProvider: fplProvider,
          onEdit: () => _openBuilder(context, teamsProvider.teams[i]),
          onDelete: () =>
              _confirmDelete(context, teamsProvider, teamsProvider.teams[i]),
        ),
      ),
    );
  }

  void _openBuilder(BuildContext context, UserTeam? team) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeamBuilderScreen(existingTeam: team)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UserTeamsProvider provider,
    UserTeam team,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.of(context).cardDark,
        title: Text(
          'Delete Team',
          style: TextStyle(color: AppColors.of(context).textPrimary),
        ),
        content: Text(
          'Delete "${team.name}"? This cannot be undone.',
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.of(context).error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteTeam(team.id);
    }
  }
}

class _TeamCard extends StatelessWidget {
  final UserTeam team;
  final FplProvider fplProvider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeamCard({
    required this.team,
    required this.fplProvider,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final prices = <int, int>{};
    for (final p in fplProvider.players) {
      prices[p.id] = p.nowCost;
    }
    final totalCost = team.totalCost(prices);
    final captain = team.captainId != 0
        ? fplProvider.getPlayerById(team.captainId)
        : null;
    final vc = team.viceCaptainId != 0
        ? fplProvider.getPlayerById(team.viceCaptainId)
        : null;
    final playerCount = team.slots.length;

    return Dismissible(
      key: ValueKey(team.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.of(context).error.withAlpha(51),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.of(context).error),
      ),
      confirmDismiss: (_) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.of(context).cardDark,
            title: Text(
              'Delete Team',
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
            content: Text(
              'Delete "${team.name}"?',
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.of(context).textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.of(context).error),
                ),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.gradientCard(context: context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${team.formation}  •  $playerCount players  •  ${_formatDate(team.createdAt)}',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.of(context).primary.withAlpha(102),
                      ),
                    ),
                    child: Text(
                      formatPrice(totalCost),
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (captain != null || vc != null) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: AppColors.of(context).divider),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (captain != null) ...[
                      _captainBadge(
                        context,
                        'C',
                        captain.webName,
                        AppColors.of(context).warning,
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (vc != null) ...[
                      _captainBadge(
                        context,
                        'V',
                        vc.webName,
                        AppColors.of(context).accent,
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Spacer(),
                    // Mini player avatars
                    _buildMiniAvatars(context, team, fplProvider),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit,
                      size: 14,
                      color: AppColors.of(context).accent,
                    ),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.of(context).accent,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: AppColors.of(context).error,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        color: AppColors.of(context).error,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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

  Widget _captainBadge(
    BuildContext context,
    String letter,
    String name,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.of(context).secondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAvatars(
    BuildContext context,
    UserTeam team,
    FplProvider fplProvider,
  ) {
    final ids = team.startingPlayerIds.take(5).toList();
    return SizedBox(
      width: ids.length * 18.0 + 8,
      height: 26,
      child: Stack(
        children: ids.asMap().entries.map((e) {
          final player = fplProvider.getPlayerById(e.value);
          return Positioned(
            left: e.key * 18.0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.of(context).cardMedium,
                border: Border.all(
                  color: AppColors.of(context).cardDark,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: player != null
                  ? CachedNetworkImage(
                      imageUrl: player.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Icon(Icons.person, size: 14),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.person, size: 14),
                    )
                  : const Icon(Icons.person, size: 14),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
