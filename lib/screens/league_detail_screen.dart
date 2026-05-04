import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fpl_service.dart';
import '../providers/fpl_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'fpl_pitch_screen.dart';

class LeagueDetailScreen extends StatefulWidget {
  final int leagueId;
  final String leagueName;
  final int? userEntryId;
  final bool isH2H;

  const LeagueDetailScreen({
    super.key,
    required this.leagueId,
    this.leagueName = '',
    this.userEntryId,
    this.isH2H = false,
  });

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen> {
  final _service = FplService();
  bool _loading = true;
  String? _error;
  List<dynamic> _standings = [];

  @override
  void initState() {
    super.initState();
    _fetchStandings();
  }

  Future<void> _fetchStandings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchLeagueStandings(widget.leagueId);
      if (mounted) {
        setState(() {
          _standings = data['standings']?['results'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(widget.leagueName),
        backgroundColor: AppColors.of(context).secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchStandings,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.of(context).primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.of(context).error, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: AppColors.of(context).textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchStandings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.of(context).primary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_standings.isEmpty) {
      return Center(
        child: Text(
          'No standings found for this league',
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _standings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entryItem = _standings[index];
        final rank = entryItem['rank'] as int? ?? 0;
        final playerName = entryItem['player_name'] as String? ?? '';
        final teamName = entryItem['entry_name'] as String? ?? '';
        final total = entryItem['total'] as int? ?? 0;
        final lastRank = entryItem['last_rank'] as int? ?? 0;
        final eventTotal = entryItem['event_total'] as int? ?? 0;

        final diff = lastRank - rank;
        Widget rankIcon;
        if (diff > 0) {
          rankIcon = const Icon(
            Icons.arrow_upward_rounded,
            color: Colors.green,
            size: 12,
          );
        } else if (diff < 0) {
          rankIcon = const Icon(
            Icons.arrow_downward_rounded,
            color: Colors.red,
            size: 12,
          );
        } else {
          rankIcon = Icon(
            Icons.remove_rounded,
            color: AppColors.of(context).textSecondary,
            size: 12,
          );
        }

        final isMe = entryItem['entry'] == widget.userEntryId;

        return GestureDetector(
          onTap: () async {
            final entryId = entryItem['entry'] as int;
            final fplProvider = context.read<FplProvider>();
            final gwId = fplProvider.currentGameweek?.id ?? 1;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Center(
                child: CircularProgressIndicator(color: AppColors.of(context).primary),
              ),
            );

            try {
              final picks = await _service.fetchFplEntryPicks(entryId, gwId);
              if (mounted) {
                Navigator.pop(context); // close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FplPitchScreen(picks: picks, gwNumber: gwId),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not load manager team: $e')),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.of(context).primary.withAlpha(20)
                  : AppColors.of(context).cardMedium,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMe
                    ? AppColors.of(context).primary.withAlpha(150)
                    : AppColors.of(context).cardDark,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    formatNumber(rank),
                    style: TextStyle(
                      color: isMe ? AppColors.of(context).primary : AppColors.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        style: TextStyle(
                          color: isMe
                              ? AppColors.of(context).primary
                              : AppColors.of(context).textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        playerName,
                        style: TextStyle(
                          color: isMe
                              ? AppColors.of(context).primary.withAlpha(200)
                              : AppColors.of(context).textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatNumber(total),
                      style: TextStyle(
                        color: isMe ? AppColors.of(context).primary : AppColors.of(context).primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GW: $eventTotal  ',
                          style: TextStyle(
                            color: isMe
                                ? AppColors.of(context).primary.withAlpha(200)
                                : AppColors.of(context).textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        rankIcon,
                        const SizedBox(width: 2),
                        Text(
                          diff == 0 ? '-' : '${diff.abs()}',
                          style: TextStyle(
                            color: diff > 0
                                ? Colors.green
                                : (diff < 0
                                      ? Colors.red
                                      : AppColors.of(context).textSecondary),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
