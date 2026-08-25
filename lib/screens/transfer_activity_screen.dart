import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'player_detail_screen.dart';

class TransferActivityScreen extends StatefulWidget {
  const TransferActivityScreen({super.key});

  @override
  State<TransferActivityScreen> createState() => _TransferActivityScreenState();
}

class _TransferActivityScreenState extends State<TransferActivityScreen> {
  int _visibleCount = 10;
  bool _showTransfersOut = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        final sorted = List<Player>.from(provider.players)
          ..sort(
            (a, b) =>
                (_showTransfersOut ? b.transfersOutEvent : b.transfersInEvent)
                    .compareTo(
                      _showTransfersOut
                          ? a.transfersOutEvent
                          : a.transfersInEvent,
                    ),
          );
        final visiblePlayers = sorted.take(_visibleCount).toList();
        final canShowMore = _visibleCount < sorted.length && _visibleCount < 50;

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('Transfer Activity'),
            backgroundColor: AppColors.of(context).secondary,
            actions: [
              IconButton(
                onPressed: () => setState(() {
                  _showTransfersOut = !_showTransfersOut;
                  _visibleCount = 10;
                }),
                icon: Icon(
                  _showTransfersOut ? Icons.arrow_downward : Icons.arrow_upward,
                  color: AppColors.of(context).primary,
                ),
              ),
            ],
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
                    final count = _showTransfersOut
                        ? player.transfersOutEvent
                        : player.transfersInEvent;
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
                            Text(
                              '$count',
                              style: TextStyle(
                                color: _showTransfersOut
                                    ? AppColors.of(context).error
                                    : AppColors.of(context).primary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
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
