import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_analytics/providers/fpl_provider.dart';

void main() {
  group('Official FPL Points & Scoring Tests', () {
    test('getOfficialStatPoints returns position-accurate points when explain is fallback', () {
      final provider = FplProvider();

      // Test default rules when explain is empty
      // Midfielder goal = 5 pts
      expect(provider.getOfficialStatPoints(101, 'goals_scored'), 5);
      // Assist = 3 pts
      expect(provider.getOfficialStatPoints(101, 'assists'), 3);
      // Yellow card = -1 pt
      expect(provider.getOfficialStatPoints(101, 'yellow_cards'), -1);
      // Red card = -3 pts
      expect(provider.getOfficialStatPoints(101, 'red_cards'), -3);
      // Penalty saved = 5 pts
      expect(provider.getOfficialStatPoints(101, 'penalties_saved'), 5);
    });

    test('calculateLiveTeamPoints handles empty picks safely without crash', () {
      final provider = FplProvider();
      final points = provider.calculateLiveTeamPoints([], gw: 1);
      expect(points, 0);
    });
  });
}
