import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_analytics/logic/fpl_rules.dart';

void main() {
  // ── Sell Price ───────────────────────────────────────────────────────────────

  group('calculateSellPrice', () {
    test('returns current price when price has not risen', () {
      expect(
        calculateSellPrice(purchasePrice: 100, currentPrice: 100),
        equals(100),
      );
    });

    test('returns current price when price has fallen', () {
      expect(
        calculateSellPrice(purchasePrice: 100, currentPrice: 95),
        equals(95),
      );
    });

    test('adds half profit (floor) when price has risen by even amount', () {
      // Bought at £10.0m (100), now £10.4m (104) → profit 4 → half = 2
      // Sell = 100 + 2 = 102 (£10.2m)
      expect(
        calculateSellPrice(purchasePrice: 100, currentPrice: 104),
        equals(102),
      );
    });

    test('floors half profit when rise is odd (0.1m = 1 unit)', () {
      // Bought at £10.0m (100), now £10.3m (103) → profit 3 → floor(3/2) = 1
      // Sell = 100 + 1 = 101 (£10.1m)
      expect(
        calculateSellPrice(purchasePrice: 100, currentPrice: 103),
        equals(101),
      );
    });

    test('floors correctly for larger rise', () {
      // Bought at £8.0m (80), now £9.5m (95) → profit 15 → floor(15/2) = 7
      // Sell = 80 + 7 = 87 (£8.7m)
      expect(
        calculateSellPrice(purchasePrice: 80, currentPrice: 95),
        equals(87),
      );
    });

    test('handles 1-unit rise: no bonus (floors to 0)', () {
      // Profit 1 → floor(1/2) = 0 → sell = purchase
      expect(
        calculateSellPrice(purchasePrice: 100, currentPrice: 101),
        equals(100),
      );
    });

    test('handles 2-unit rise: half = 1', () {
      expect(
        calculateSellPrice(purchasePrice: 100, currentPrice: 102),
        equals(101),
      );
    });
  });

  // ── Free Transfers ───────────────────────────────────────────────────────────

  group('bankFreeTransfers', () {
    test('1 FT, 0 transfers made → 2 FTs next week', () {
      expect(
        bankFreeTransfers(currentFreeTransfers: 1, transfersMadeThisWeek: 0),
        equals(2),
      );
    });

    test('1 FT, 1 transfer made → 1 FT next week', () {
      expect(
        bankFreeTransfers(currentFreeTransfers: 1, transfersMadeThisWeek: 1),
        equals(1),
      );
    });

    test('2 FTs, 0 transfers made → 3 FTs next week', () {
      expect(
        bankFreeTransfers(currentFreeTransfers: 2, transfersMadeThisWeek: 0),
        equals(3),
      );
    });

    test('caps at maxBanked (default 5)', () {
      expect(
        bankFreeTransfers(currentFreeTransfers: 5, transfersMadeThisWeek: 0),
        equals(5),
      );
    });

    test('caps at custom maxBanked', () {
      expect(
        bankFreeTransfers(
          currentFreeTransfers: 3,
          transfersMadeThisWeek: 0,
          maxBanked: 3,
        ),
        equals(3),
      );
    });

    test('making more transfers than FTs available does not go below 1', () {
      // 1 FT, 3 transfers → unused = 0, next = 1
      expect(
        bankFreeTransfers(currentFreeTransfers: 1, transfersMadeThisWeek: 3),
        equals(1),
      );
    });

    test('4 FTs, 2 transfers made → 3 FTs next week', () {
      expect(
        bankFreeTransfers(currentFreeTransfers: 4, transfersMadeThisWeek: 2),
        equals(3),
      );
    });
  });

  // ── Hits ─────────────────────────────────────────────────────────────────────

  group('calculateHits', () {
    test('no transfers beyond free → 0 hit cost', () {
      expect(
        calculateHits(transfersMade: 1, freeTransfers: 1),
        equals(0),
      );
    });

    test('1 extra transfer → -4 points', () {
      expect(
        calculateHits(transfersMade: 2, freeTransfers: 1),
        equals(-4),
      );
    });

    test('2 extra transfers → -8 points', () {
      expect(
        calculateHits(transfersMade: 3, freeTransfers: 1),
        equals(-8),
      );
    });

    test('wildcard chip active → 0 hit cost regardless', () {
      expect(
        calculateHits(
          transfersMade: 10,
          freeTransfers: 1,
          chipActive: true,
        ),
        equals(0),
      );
    });

    test('0 transfers made → 0 hit cost', () {
      expect(
        calculateHits(transfersMade: 0, freeTransfers: 1),
        equals(0),
      );
    });

    test('2 FTs, 2 transfers made → no hit', () {
      expect(
        calculateHits(transfersMade: 2, freeTransfers: 2),
        equals(0),
      );
    });

    test('2 FTs, 4 transfers made → -8 points', () {
      expect(
        calculateHits(transfersMade: 4, freeTransfers: 2),
        equals(-8),
      );
    });
  });

  // ── Captain / Vice-Captain ────────────────────────────────────────────────────

  group('resolveCaptain', () {
    test('captain played → captain gets bonus', () {
      final captainStats = LivePlayerStats(playerId: 1, minutes: 90, rawPoints: 10);
      final viceStats = LivePlayerStats(playerId: 2, minutes: 90, rawPoints: 8);

      final result = resolveCaptain(
        captainStats: captainStats,
        viceCaptainStats: viceStats,
        gwHasStarted: true,
      );

      expect(result.captainId, equals(1));
      expect(result.usingVice, isFalse);
      expect(result.totalPoints, equals(10)); // captain raw points
    });

    test('captain did not play → vice gets bonus', () {
      final captainStats = LivePlayerStats(playerId: 1, minutes: 0, rawPoints: 2);
      final viceStats = LivePlayerStats(playerId: 2, minutes: 72, rawPoints: 9);

      final result = resolveCaptain(
        captainStats: captainStats,
        viceCaptainStats: viceStats,
        gwHasStarted: true,
      );

      expect(result.captainId, equals(2)); // vice becomes effective captain
      expect(result.usingVice, isTrue);
      expect(result.totalPoints, equals(9));
    });

    test('captain has 0 minutes but GW not started → captain still chosen', () {
      final captainStats = LivePlayerStats(playerId: 1, minutes: 0, rawPoints: 0);
      final viceStats = LivePlayerStats(playerId: 2, minutes: 0, rawPoints: 0);

      final result = resolveCaptain(
        captainStats: captainStats,
        viceCaptainStats: viceStats,
        gwHasStarted: false,
      );

      expect(result.captainId, equals(1));
      expect(result.usingVice, isFalse);
    });

    test('captain played 1 minute → captain keeps bonus', () {
      final captainStats = LivePlayerStats(playerId: 1, minutes: 1, rawPoints: 3);
      final viceStats = LivePlayerStats(playerId: 2, minutes: 90, rawPoints: 15);

      final result = resolveCaptain(
        captainStats: captainStats,
        viceCaptainStats: viceStats,
        gwHasStarted: true,
      );

      expect(result.captainId, equals(1));
      expect(result.usingVice, isFalse);
    });
  });

  // ── Auto-Substitutions ────────────────────────────────────────────────────────

  group('applyAutoSubs', () {
    // Helper to create a standard 4-4-2 squad
    // Slots: 0=GK, 1-4=DEF, 5-8=MID, 9-10=FWD, 11=benchGK, 12-14=bench outfield
    List<SquadSlot> _build442() => [
          const SquadSlot(playerId: 1, position: 1, slotIndex: 0), // GK
          const SquadSlot(playerId: 2, position: 2, slotIndex: 1), // DEF
          const SquadSlot(playerId: 3, position: 2, slotIndex: 2), // DEF
          const SquadSlot(playerId: 4, position: 2, slotIndex: 3), // DEF
          const SquadSlot(playerId: 5, position: 2, slotIndex: 4), // DEF
          const SquadSlot(playerId: 6, position: 3, slotIndex: 5), // MID
          const SquadSlot(playerId: 7, position: 3, slotIndex: 6), // MID
          const SquadSlot(playerId: 8, position: 3, slotIndex: 7), // MID
          const SquadSlot(playerId: 9, position: 3, slotIndex: 8), // MID
          const SquadSlot(playerId: 10, position: 4, slotIndex: 9), // FWD
          const SquadSlot(playerId: 11, position: 4, slotIndex: 10), // FWD
          const SquadSlot(playerId: 12, position: 1, slotIndex: 11), // bench GK
          const SquadSlot(playerId: 13, position: 3, slotIndex: 12), // bench1
          const SquadSlot(playerId: 14, position: 2, slotIndex: 13), // bench2
          const SquadSlot(playerId: 15, position: 4, slotIndex: 14), // bench3
        ];

    Map<int, LivePlayerStats> _allPlayed(List<SquadSlot> squad) {
      return {
        for (final s in squad)
          s.playerId: LivePlayerStats(
            playerId: s.playerId,
            minutes: 90,
            rawPoints: 5,
          )
      };
    }

    test('no subs needed when all starting players played', () {
      final squad = _build442();
      final stats = _allPlayed(squad);
      final result = applyAutoSubs(
        squad: squad,
        liveStats: stats,
        gwHasStarted: true,
      );
      expect(result.subs, isEmpty);
      expect(result.unresolved, isEmpty);
    });

    test('GW not started → no subs', () {
      final squad = _build442();
      // Make a starting player not play
      final stats = _allPlayed(squad)
        ..[2] = const LivePlayerStats(playerId: 2, minutes: 0, rawPoints: 0);
      final result = applyAutoSubs(
        squad: squad,
        liveStats: stats,
        gwHasStarted: false,
      );
      expect(result.subs, isEmpty);
    });

    test('one starting outfield player absent → bench1 comes on', () {
      final squad = _build442();
      // DEF #2 did not play; bench1 (MID, slot 12) played
      final stats = _allPlayed(squad)
        ..[2] = const LivePlayerStats(playerId: 2, minutes: 0, rawPoints: 0);

      final result = applyAutoSubs(
        squad: squad,
        liveStats: stats,
        gwHasStarted: true,
      );

      // Player 2 should be replaced by bench player 13 (first eligible bench outfield)
      expect(result.subs.containsKey(2), isTrue);
      expect(result.subs[2], equals(13));
    });

    test('GK absent → bench GK comes on', () {
      final squad = _build442();
      final stats = _allPlayed(squad)
        ..[1] = const LivePlayerStats(playerId: 1, minutes: 0, rawPoints: 0);

      final result = applyAutoSubs(
        squad: squad,
        liveStats: stats,
        gwHasStarted: true,
      );

      expect(result.subs[1], equals(12)); // bench GK
    });

    test('bench player also did not play → skipped, next bench tried', () {
      final squad = _build442();
      // DEF #2 did not play; bench1 (id=13, MID) also did not play
      // bench2 (id=14, DEF) played → should come on
      final stats = _allPlayed(squad)
        ..[2] = const LivePlayerStats(playerId: 2, minutes: 0, rawPoints: 0)
        ..[13] = const LivePlayerStats(playerId: 13, minutes: 0, rawPoints: 0);

      final result = applyAutoSubs(
        squad: squad,
        liveStats: stats,
        gwHasStarted: true,
      );

      expect(result.subs[2], equals(14));
    });

    test('formation constraint blocks sub that would leave < 3 DEF', () {
      // Setup: 3 DEF in starting XI; one DEF absent; only bench player is FWD
      // Bringing in an FWD would leave 2 DEF → illegal
      final squad = [
        const SquadSlot(playerId: 1, position: 1, slotIndex: 0), // GK
        const SquadSlot(playerId: 2, position: 2, slotIndex: 1), // DEF
        const SquadSlot(playerId: 3, position: 2, slotIndex: 2), // DEF
        const SquadSlot(playerId: 4, position: 2, slotIndex: 3), // DEF - will not play
        const SquadSlot(playerId: 5, position: 3, slotIndex: 4), // MID
        const SquadSlot(playerId: 6, position: 3, slotIndex: 5), // MID
        const SquadSlot(playerId: 7, position: 3, slotIndex: 6), // MID
        const SquadSlot(playerId: 8, position: 3, slotIndex: 7), // MID
        const SquadSlot(playerId: 9, position: 3, slotIndex: 8), // MID
        const SquadSlot(playerId: 10, position: 4, slotIndex: 9), // FWD
        const SquadSlot(playerId: 11, position: 4, slotIndex: 10), // FWD
        const SquadSlot(playerId: 12, position: 1, slotIndex: 11), // bench GK
        const SquadSlot(playerId: 13, position: 4, slotIndex: 12), // bench FWD (only option)
        const SquadSlot(playerId: 14, position: 4, slotIndex: 13), // bench FWD
        const SquadSlot(playerId: 15, position: 4, slotIndex: 14), // bench FWD
      ];

      final stats = <int, LivePlayerStats>{
        for (int i = 1; i <= 15; i++)
          i: LivePlayerStats(playerId: i, minutes: i == 4 ? 0 : 90, rawPoints: 5)
      };

      final result = applyAutoSubs(
        squad: squad,
        liveStats: stats,
        gwHasStarted: true,
      );

      // No valid sub exists (would break 3-DEF min); player 4 should be unresolved
      expect(result.subs.containsKey(4), isFalse);
      expect(result.unresolved.contains(4), isTrue);
    });
  });

  // ── Chip Helpers ──────────────────────────────────────────────────────────────

  group('isChipUsed', () {
    test('returns true when chip matches activeChip', () {
      expect(
        isChipUsed(
          chipName: ChipNames.wildcard,
          activeChip: ChipNames.wildcard,
        ),
        isTrue,
      );
    });

    test('returns true when chip is in usedChips list', () {
      expect(
        isChipUsed(
          chipName: ChipNames.benchBoost,
          usedChips: [ChipNames.benchBoost, ChipNames.freeHit],
        ),
        isTrue,
      );
    });

    test('returns false when chip not used', () {
      expect(
        isChipUsed(
          chipName: ChipNames.tripleCaptain,
          activeChip: ChipNames.wildcard,
          usedChips: [ChipNames.benchBoost],
        ),
        isFalse,
      );
    });
  });

  group('activeChip', () {
    test('returns null for empty string', () {
      expect(activeChip(''), isNull);
    });

    test('returns null for null', () {
      expect(activeChip(null), isNull);
    });

    test('returns chip name when present', () {
      expect(activeChip(ChipNames.freeHit), equals(ChipNames.freeHit));
    });
  });
}
