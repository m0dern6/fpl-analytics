import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class PitchView extends StatelessWidget {
  final List<Map<String, dynamic>> picks;
  final FplProvider provider;
  final int gwId;
  final String? activeChip;
  final Map<int, int>? pointsMap;
  final bool isDreamTeam;
  final Function(Map<String, dynamic> pick) onPlayerTap;

  const PitchView({
    super.key,
    required this.picks,
    required this.provider,
    required this.gwId,
    this.activeChip,
    this.pointsMap,
    this.isDreamTeam = false,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (picks.isEmpty) return const SizedBox.shrink();

    final starting = picks.where((p) => (p['position'] as int) <= 11).toList()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

    final bench = picks.where((p) => (p['position'] as int) > 11).toList()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

    final gkPicks = _filterByPos(starting, 1);
    final defPicks = _filterByPos(starting, 2);
    final midPicks = _filterByPos(starting, 3);
    final fwdPicks = _filterByPos(starting, 4);

    final pitchContent = Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _FplPitchPainter())),
        Column(
          children: [
            const SizedBox(height: 20),
            _buildPitchRow(gkPicks, isStarting: true),
            const SizedBox(height: 6),
            _buildPitchRow(defPicks, isStarting: true),
            const SizedBox(height: 6),
            _buildPitchRow(midPicks, isStarting: true),
            const SizedBox(height: 6),
            _buildPitchRow(fwdPicks, isStarting: true),
            if (bench.isNotEmpty || isDreamTeam) ...[
              const SizedBox(height: 10),
              _buildBenchDivider(activeChip == 'bboost'),
              const SizedBox(height: 8),
              if (bench.isNotEmpty) _buildPitchRow(bench, isStarting: false),
              if (bench.isEmpty && isDreamTeam)
                // show 4 empty spots for bench in dream team
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (_) =>
                          Opacity(opacity: 0.5, child: _buildEmptyBenchSpot()),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ],
    );

    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0006)
        ..rotateX(0.12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: pitchContent,
      ),
    );
  }

  Widget _buildEmptyBenchSpot() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white54, size: 24),
        ),
        const SizedBox(height: 6),
        Container(
          width: 50,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterByPos(
    List<Map<String, dynamic>> list,
    int type,
  ) {
    return list.where((p) {
      final player = provider.getPlayerById(p['element'] as int);
      return player?.elementType == type;
    }).toList();
  }

  Widget _buildPitchRow(
    List<Map<String, dynamic>> picksRow, {
    required bool isStarting,
  }) {
    if (picksRow.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: picksRow.map((pick) {
          final player = provider.getPlayerById(pick['element'] as int);
          final posLabel = player != null
              ? getPositionShort(player.elementType)
              : '';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isStarting && posLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    posLabel,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              _PitchPlayerCard(
                pick: pick,
                provider: provider,
                isStarting: isStarting,
                gwId: gwId,
                activeChip: activeChip,
                pointsMap: pointsMap,
                isDreamTeam: isDreamTeam,
                onTap: () => onPlayerTap(pick),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBenchDivider(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF34D399).withAlpha(40)
            : Colors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? const Color(0xFF34D399).withAlpha(120)
              : Colors.white.withAlpha(25),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.bolt_rounded : Icons.chair_rounded,
            color: isActive ? const Color(0xFF34D399) : Colors.white38,
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'BENCH BOOST ACTIVE' : 'SUBSTITUTES',
            style: TextStyle(
              color: isActive ? const Color(0xFF34D399) : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: isActive ? 1 : 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FplPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const stripe1 = Color(0xFF2FA84E);
    const stripe2 = Color(0xFF35B857);
    final nStripes = 10;
    final stripeH = h / nStripes;
    for (int i = 0; i < nStripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, w, stripeH),
        Paint()..color = i.isEven ? stripe1 : stripe2,
      );
    }

    final lp = Paint()
      ..color = Colors.white.withAlpha(210)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final spotPaint = Paint()
      ..color = Colors.white.withAlpha(210)
      ..style = PaintingStyle.fill;

    const border = 10.0;
    final innerW = w - 2 * border;
    final innerH = h - 2 * border;

    double px(double nx) => border + nx * innerW;
    double py(double ny) => border + ny * innerH;

    canvas.drawRect(Rect.fromLTWH(border, border, innerW, innerH), lp);
    canvas.drawLine(
      Offset(border, py(0.5)),
      Offset(border + innerW, py(0.5)),
      lp,
    );

    final ccRadius = innerW * 0.14;
    canvas.drawCircle(Offset(px(0.5), py(0.5)), ccRadius, lp);
    canvas.drawCircle(Offset(px(0.5), py(0.5)), 3.0, spotPaint);

    final tPAW = innerW * 0.60;
    final tPAH = innerH * 0.175;
    canvas.drawRect(Rect.fromLTWH(px(0.5) - tPAW / 2, border, tPAW, tPAH), lp);

    final tGAW = innerW * 0.30;
    final tGAH = innerH * 0.065;
    canvas.drawRect(Rect.fromLTWH(px(0.5) - tGAW / 2, border, tGAW, tGAH), lp);

    final goalW = innerW * 0.13;
    const goalDepth = 12.0;
    final goalLp = Paint()
      ..color = Colors.white.withAlpha(230)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final tGoalLeft = px(0.5) - goalW / 2;
    final tGoalRight = px(0.5) + goalW / 2;
    final tGoalCrossbar = border;
    final tGoalTop = border - goalDepth;
    canvas.drawLine(
      Offset(tGoalLeft, tGoalCrossbar),
      Offset(tGoalLeft, tGoalTop),
      goalLp,
    );
    canvas.drawLine(
      Offset(tGoalRight, tGoalCrossbar),
      Offset(tGoalRight, tGoalTop),
      goalLp,
    );
    canvas.drawLine(
      Offset(tGoalLeft, tGoalTop),
      Offset(tGoalRight, tGoalTop),
      goalLp,
    );

    const tSpotNy = 0.115;
    canvas.drawCircle(Offset(px(0.5), py(tSpotNy)), 2.5, spotPaint);

    final tArcCenter = Offset(px(0.5), py(tSpotNy));
    final arcR = ccRadius;
    final tPABottom = border + tPAH;
    final tSinTheta = (tPABottom - tArcCenter.dy).clamp(-arcR, arcR) / arcR;
    final tTheta = math.asin(tSinTheta.toDouble());
    if (tTheta < math.pi / 2) {
      final arcStartAngle = math.pi / 2 - tTheta - 0.02;
      final arcSweep = math.pi - (math.pi / 2 - tTheta) * 2 + 0.04;
      if (arcSweep > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: tArcCenter, radius: arcR),
          arcStartAngle,
          arcSweep,
          false,
          lp,
        );
      }
    }

    canvas.drawRect(
      Rect.fromLTWH(px(0.5) - tPAW / 2, border + innerH - tPAH, tPAW, tPAH),
      lp,
    );
    canvas.drawRect(
      Rect.fromLTWH(px(0.5) - tGAW / 2, border + innerH - tGAH, tGAW, tGAH),
      lp,
    );

    final bGoalLeft = px(0.5) - goalW / 2;
    final bGoalRight = px(0.5) + goalW / 2;
    final bGoalCrossbar = border + innerH;
    final bGoalBottom = border + innerH + goalDepth;
    canvas.drawLine(
      Offset(bGoalLeft, bGoalCrossbar),
      Offset(bGoalLeft, bGoalBottom),
      goalLp,
    );
    canvas.drawLine(
      Offset(bGoalRight, bGoalCrossbar),
      Offset(bGoalRight, bGoalBottom),
      goalLp,
    );
    canvas.drawLine(
      Offset(bGoalLeft, bGoalBottom),
      Offset(bGoalRight, bGoalBottom),
      goalLp,
    );

    const bSpotNy = 1.0 - tSpotNy;
    canvas.drawCircle(Offset(px(0.5), py(bSpotNy)), 2.5, spotPaint);

    final bArcCenter = Offset(px(0.5), py(bSpotNy));
    final bPATop = border + innerH - tPAH;
    final bSinTheta = (bArcCenter.dy - bPATop).clamp(-arcR, arcR) / arcR;
    final bTheta = math.asin(bSinTheta.toDouble());
    if (bTheta < math.pi / 2) {
      final arcStartAngle = -math.pi / 2 - bTheta - 0.02 + math.pi;
      final arcSweep = math.pi - (math.pi / 2 - bTheta) * 2 + 0.04;
      if (arcSweep > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: bArcCenter, radius: arcR),
          arcStartAngle,
          arcSweep,
          false,
          lp,
        );
      }
    }

    final cr = innerW * 0.030;
    final cornerLp = Paint()
      ..color = Colors.white.withAlpha(200)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(border, border),
        width: cr * 2,
        height: cr * 2,
      ),
      0,
      math.pi / 2,
      false,
      cornerLp,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(border + innerW, border),
        width: cr * 2,
        height: cr * 2,
      ),
      math.pi / 2,
      math.pi / 2,
      false,
      cornerLp,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(border, border + innerH),
        width: cr * 2,
        height: cr * 2,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      cornerLp,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(border + innerW, border + innerH),
        width: cr * 2,
        height: cr * 2,
      ),
      math.pi,
      math.pi / 2,
      false,
      cornerLp,
    );

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withAlpha(60)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _CardState { captain, viceCaptain, topPerformer, good, regular, bench }

class _PitchPlayerCard extends StatelessWidget {
  final Map<String, dynamic> pick;
  final FplProvider provider;
  final bool isStarting;
  final int gwId;
  final String? activeChip;
  final Map<int, int>? pointsMap;
  final bool isDreamTeam;
  final VoidCallback onTap;

  const _PitchPlayerCard({
    required this.pick,
    required this.provider,
    required this.isStarting,
    required this.gwId,
    this.activeChip,
    this.pointsMap,
    this.isDreamTeam = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playerId = pick['element'] as int;
    final isCaptain = pick['is_captain'] as bool? ?? false;
    final isViceCaptain = pick['is_vice_captain'] as bool? ?? false;
    final multiplier = pick['multiplier'] as int? ?? 1;
    final isBench = (pick['position'] as int) > 11;

    final player = provider.getPlayerById(playerId);

    int effectivePts;
    if (pointsMap != null && pointsMap!.containsKey(playerId)) {
      effectivePts = pointsMap![playerId]!;
    } else {
      final live = provider.getLiveStatsForPlayer(playerId);
      final rawPts = live?['total_points'] as int? ?? 0;
      effectivePts = isBench ? rawPts : rawPts * multiplier;
    }

    final posColor = player != null
        ? getPositionColor(player.elementType)
        : AppColors.textSecondary;

    final _CardState state;
    if (isCaptain) {
      state = _CardState.captain;
    } else if (isViceCaptain) {
      state = _CardState.viceCaptain;
    } else if (!isBench && effectivePts >= 10) {
      state = _CardState.topPerformer;
    } else if (!isBench && effectivePts >= 6) {
      state = _CardState.good;
    } else if (isBench) {
      state = _CardState.bench;
    } else {
      state = _CardState.regular;
    }

    Color borderColor;
    Gradient? cardGradient;

    switch (state) {
      case _CardState.captain:
        borderColor = const Color(0xFFFFD700);
        cardGradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33FFD700), Color(0x1A150505)],
        );
      case _CardState.viceCaptain:
        borderColor = AppColors.accent;
        cardGradient = null;
      case _CardState.topPerformer:
        borderColor = AppColors.primary;
        cardGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withAlpha(30), Colors.white.withAlpha(10)],
        );
      case _CardState.good:
        borderColor = const Color(0xFF34D399);
        cardGradient = null;
      case _CardState.bench:
        borderColor = Colors.white.withAlpha(40);
        cardGradient = null;
      case _CardState.regular:
        borderColor = posColor.withAlpha(160);
        cardGradient = null;
    }

    if (activeChip == 'bboost' && !isStarting) {
      borderColor = const Color(0xFF34D399);
    }

    const cardWidth = 60.0;
    const cardHeight = 64.0;

    final photoCard = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            color: Colors.white.withAlpha(10), // Glassy background
            gradient: cardGradient,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (player != null)
                CachedNetworkImage(
                  imageUrl: player.photoUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  placeholder: (_, __) => Center(
                    child: Icon(Icons.person, color: posColor, size: 26),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: Icon(Icons.person, color: posColor, size: 26),
                  ),
                )
              else
                Center(child: Icon(Icons.person, color: posColor, size: 26)),

              if (isCaptain)
                Positioned(
                  top: 4,
                  left: 4,
                  child: _buildBadge('C', isTriple: activeChip == '3xc'),
                )
              else if (isViceCaptain)
                Positioned(top: 4, left: 4, child: _buildBadge('V')),
            ],
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            photoCard,
            Container(
              width: cardWidth,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(isBench ? 120 : 180),
              ),
              child: Text(
                player?.webName ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: cardWidth,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: _ptsBadgeColor(state, effectivePts),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              child: Text(
                _getStatusText(player, effectivePts),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(Player? player, int points) {
    if (player == null) return '?';
    if (isDreamTeam) return '$points pts';

    final fixtures =
        provider
            .getFixturesForGameweek(gwId)
            .where(
              (f) =>
                  f.homeTeamId == player.teamId ||
                  f.awayTeamId == player.teamId,
            )
            .toList()
          ..sort(
            (a, b) => (a.kickoffTime ?? '').compareTo(b.kickoffTime ?? ''),
          );

    if (fixtures.isEmpty) return '$points pts';

    final isBench = (pick['position'] as int) > 11;
    int effectivePts = points;

    bool anyStarted = fixtures.any((f) => f.started ?? false);
    bool allFinished = fixtures.every((f) => f.finished);

    if (!anyStarted) {
      return fixtures
          .map((f) {
            final isHome = f.homeTeamId == player.teamId;
            final oppId = isHome ? f.awayTeamId : f.homeTeamId;
            final opp = provider.getTeamById(oppId);
            final shortName = opp?.shortName ?? 'OPP';
            return '$shortName(${isHome ? 'H' : 'A'})';
          })
          .join(',');
    }

    if (allFinished) return '$effectivePts pts';

    final pending = fixtures.where((f) => !(f.started ?? false)).toList();
    if (pending.isEmpty) return '$effectivePts pts';

    final pendingStr = pending
        .map((f) {
          final isHome = f.homeTeamId == player.teamId;
          final oppId = isHome ? f.awayTeamId : f.homeTeamId;
          final opp = provider.getTeamById(oppId);
          final shortName = opp?.shortName ?? 'OPP';
          return '$shortName(${isHome ? 'H' : 'A'})';
        })
        .join(',');

    return '$effectivePts pts,$pendingStr';
  }

  Widget _buildBadge(String letter, {bool isTriple = false}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isTriple ? Colors.white : Colors.black,
        shape: BoxShape.circle,
        border: Border.all(
          color: isTriple ? Colors.black : Colors.white,
          width: 0.8,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            color: isTriple ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Color _ptsBadgeColor(_CardState state, int pts) {
    switch (state) {
      case _CardState.captain:
        return AppColors.accent;
      case _CardState.viceCaptain:
        return AppColors.primary;
      case _CardState.topPerformer:
        return AppColors.primary;
      case _CardState.good:
        return const Color(0xFF34D399);
      case _CardState.bench:
        return AppColors.primary.withAlpha(90);
      case _CardState.regular:
        return AppColors.primary.withAlpha(160);
    }
    return AppColors.primary.withAlpha(160);
  }
}
