import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'player_detail_screen.dart';

class FormLeadersScreen extends StatelessWidget {
  const FormLeadersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final players = List<Player>.from(
          provider.getTopScorersByForm(limit: 20),
        );
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Form Leaders'),
            backgroundColor: AppColors.of(context).secondary,
          ),
          body: provider.isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.of(context).primary),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.gradientCard(context: context, ),
                      child: Text(
                        'Current top-form players by 5-game rolling average.',
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...players.asMap().entries.map((entry) {
                      final index = entry.key;
                      final player = entry.value;
                      final team = provider.getTeamById(player.teamId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlayerDetailScreen(player: player),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: AppTheme.gradientCard(context: context, ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: index == 0
                                          ? AppColors.of(context).primary
                                          : AppColors.of(context).textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.of(context).cardMedium,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: player.photoUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Icon(
                                      Icons.person,
                                      color: AppColors.of(context).textSecondary,
                                      size: 18,
                                    ),
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.person,
                                      color: AppColors.of(context).textSecondary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.webName,
                                        style: TextStyle(
                                          color: AppColors.of(context).textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${team?.shortName ?? ''} · ${formatPrice(player.nowCost)}',
                                        style: TextStyle(
                                          color: AppColors.of(context).textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatForm(player.form),
                                  style: TextStyle(
                                    color: AppColors.of(context).accent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }
}
