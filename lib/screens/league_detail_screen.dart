import 'package:flutter/material.dart';
import '../services/fpl_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class LeagueDetailScreen extends StatefulWidget {
  final int leagueId;
  final String leagueName;

  const LeagueDetailScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.leagueName),
        backgroundColor: AppColors.secondary,
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchStandings,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_standings.isEmpty) {
      return const Center(
        child: Text('No standings found for this league', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _standings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = _standings[index];
        final rank = entry['rank'] as int? ?? 0;
        final playerName = entry['player_name'] as String? ?? '';
        final teamName = entry['entry_name'] as String? ?? '';
        final total = entry['total'] as int? ?? 0;
        final lastRank = entry['last_rank'] as int? ?? 0;

        final diff = lastRank - rank;
        Widget rankIcon;
        if (diff > 0) {
          rankIcon = const Icon(Icons.arrow_upward_rounded, color: Colors.green, size: 12);
        } else if (diff < 0) {
          rankIcon = const Icon(Icons.arrow_downward_rounded, color: Colors.red, size: 12);
        } else {
          rankIcon = const Icon(Icons.remove_rounded, color: AppColors.textSecondary, size: 12);
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.gradientCard(),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  formatNumber(rank),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      playerName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
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
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      rankIcon,
                      const SizedBox(width: 2),
                      Text(
                        diff == 0 ? '-' : '${diff.abs()}',
                        style: TextStyle(
                          color: diff > 0 ? Colors.green : (diff < 0 ? Colors.red : AppColors.textSecondary),
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
        );
      },
    );
  }
}
