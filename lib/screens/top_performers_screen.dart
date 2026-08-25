import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/player.dart';
import '../providers/fpl_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'player_detail_screen.dart';

class TopPerformersScreen extends StatefulWidget {
  const TopPerformersScreen({super.key});

  @override
  State<TopPerformersScreen> createState() => _TopPerformersScreenState();
}

class _TopPerformersScreenState extends State<TopPerformersScreen> {
  int _visibleCount = 10;

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final allPlayers = provider.getTopScorersByPoints(limit: 50);
        final visiblePlayers = allPlayers.take(_visibleCount).toList();
        final canShowMore =
            _visibleCount < allPlayers.length && _visibleCount < 50;

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Top Performers'),
            backgroundColor: AppColors.of(context).secondary,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visiblePlayers.length,
                  itemBuilder: (context, index) {
                    final player = visiblePlayers[index];
                    final team = provider.getTeamById(player.teamId);
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerDetailScreen(player: player),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.gradientCard(context: context),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: AppColors.of(context).primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.of(context).cardMedium,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: player.photoUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Icon(
                                  Icons.person,
                                  color: AppColors.of(context).textSecondary,
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.person,
                                  color: AppColors.of(context).textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.webName,
                                    style: TextStyle(
                                      color: AppColors.of(context).textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    team?.shortName ?? '',
                                    style: TextStyle(
                                      color: AppColors.of(
                                        context,
                                      ).textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${player.totalPoints}',
                                  style: TextStyle(
                                    color: AppColors.of(context).primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Pts',
                                  style: TextStyle(
                                    color: AppColors.of(context).textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (canShowMore)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: OutlinedButton(
                    onPressed: () => setState(
                      () => _visibleCount = (_visibleCount + 10).clamp(0, 50),
                    ),
                    child: const Text('Show More'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
