# FPL Analytics — Architecture Overview & How to Run

---

## How to Run

### Prerequisites
- Flutter SDK ≥ 3.11 (Dart ≥ 3.4)  
- Xcode 15+ (iOS) or Android Studio (Android)
- A device / simulator / emulator

### Clone & install
```bash
git clone https://github.com/m0dern6/fpl-analytics.git
cd fpl-analytics
flutter pub get
```

### Run on simulator / device
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Chrome (web - limited functionality)
flutter run -d chrome
```

### Run tests
```bash
flutter test
```

### Build release
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
# or
flutter build appbundle --release
```

---

## Architecture Overview

### Tech Stack
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State management | Provider (`ChangeNotifier`) |
| HTTP | `package:http` |
| Local storage | `shared_preferences` |
| Image caching | `cached_network_image` |
| Charts | `fl_chart` |
| Fonts | `google_fonts` (Inter) |
| Animations | `flutter_animate`, `shimmer` |

---

### Folder Structure

```
lib/
├── main.dart                   # App entry, Provider setup
├── logic/
│   └── fpl_rules.dart          # Pure functions: captain/vice, auto-subs,
│                               #   sell price, FT banking, hit calc, chips
├── models/
│   ├── player.dart             # Player with all API fields
│   ├── team.dart               # PL club
│   ├── gameweek.dart           # Event / GW
│   ├── fixture.dart            # Fixture + stats
│   ├── player_history.dart     # Per-GW player history
│   ├── element_type.dart       # Position type metadata
│   ├── entry.dart              # FPL entry + picks + chips (NEW)
│   └── user_team.dart          # Locally-saved team draft
├── services/
│   ├── fpl_service.dart        # API client (all official endpoints)
│   └── local_storage_service.dart  # Persistence (SharedPreferences, TTL)
├── providers/
│   ├── fpl_provider.dart       # Global FPL data + AI picks engine
│   ├── fpl_entry_provider.dart # Per-entry state (picks, history, chips) (NEW)
│   ├── user_teams_provider.dart# Local draft teams
│   └── theme_provider.dart     # Dark/light mode
├── screens/
│   ├── main_navigation_screen.dart # Bottom tab shell
│   ├── dashboard_screen.dart       # Home tab
│   ├── players_screen.dart         # Players tab
│   ├── live_screen.dart            # Live GW Center (NEW)
│   ├── leagues_screen.dart         # Leagues tab (NEW)
│   ├── transfer_planner_screen.dart# Transfer planning (NEW)
│   ├── onboarding_screen.dart      # Entry ID setup (NEW)
│   ├── fpl_team_screen.dart        # Linked team view (entry picks)
│   ├── player_detail_screen.dart   # Full player profile
│   ├── fixture_detail_screen.dart
│   ├── league_detail_screen.dart
│   ├── team_builder_screen.dart    # Local draft builder
│   ├── ai_picks_screen.dart        # AI recommendations
│   └── ...                         # Other subscreens
├── widgets/
│   ├── offline_banner.dart     # "Offline — cached data from…" (NEW)
│   ├── player_card.dart        # Player list tile
│   ├── pitch_view.dart         # Pitch formation visualiser
│   ├── loading_widget.dart     # Shimmer skeleton
│   ├── difficulty_badge.dart   # FDR colored badge
│   └── stat_card.dart
└── utils/
    ├── constants.dart          # API URLs, AppColors, position/difficulty maps
    ├── app_theme.dart          # ThemeData (light + dark)
    └── formatters.dart         # Price, date, status formatters
```

---

### Data Flow

```
Official FPL API
        │
        ▼
  FplService (HTTP + in-memory + disk cache with TTL)
        │
        ├──▶ FplProvider   (global: players, teams, GWs, fixtures, live data)
        │         │
        │         └──▶ computePlayerScore / computeAiTeam (projection engine)
        │
        └──▶ FplEntryProvider  (per-entry: picks, history, chips, bank, FTs)
                  │
                  └──▶ FplRules  (pure logic: auto-subs, sell price, hits…)

UI Screens ◀──── Provider.of / Consumer ────▶ State
```

---

### Key Design Decisions

#### Caching Strategy
- **Bootstrap-static** (players, teams, events): 5 min in-memory, 1 hr disk
- **Fixtures**: 5 min in-memory, 30 min disk
- **Player summaries**: 15 min disk per player
- **Entry picks**: 10 min disk per (entryId, gw)
- **Live GW**: 2 min in-memory (no disk — time-critical)
- **Offline mode**: Last-cached data shown with timestamp banner when network unavailable

#### Rule Logic (`lib/logic/fpl_rules.dart`)
All FPL scoring rules are implemented as **pure functions** (no side effects, no Flutter dependency) to be easily unit-tested:
- `captainPoints()` — captain/vice resolution
- `applyAutoSubs()` — bench sub eligibility + formation legality
- `calculateSellPrice()` — official half-profit rounding
- `bankFreeTransfers()` — FT rollover with configurable max
- `calculateHits()` — hit points deduction
- `isChipActive()` — chip state helper

#### Projections Engine
Uses only official API fields:
1. Recent form (last 4 GW average)
2. Points per game (season)
3. ICT index
4. Fixture difficulty rating (next GW or average 5 GW for wildcard)
5. Availability (chance of playing %)
6. Expected goals + assists (from official API)
7. Transfer momentum

All projections are labeled **"Model-based estimate"** in the UI. No third-party xG feeds.

---

### Official API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| `/bootstrap-static/` | All players, teams, events, game settings |
| `/fixtures/` | Full season fixtures |
| `/fixtures/?event=N` | GW-specific fixtures |
| `/element-summary/{id}/` | Player history + upcoming fixtures |
| `/event/{gw}/live/` | Live GW scores, BPS |
| `/dream-team/{gw}/` | GW dream team |
| `/entry/{id}/` | Manager entry details |
| `/entry/{id}/event/{gw}/picks/` | Manager picks for a GW |
| `/entry/{id}/history/` | Season + chip history |
| `/entry/{id}/transfers/` | Transfer history |
| `/leagues-classic/{id}/standings/` | Classic league standings |
| `/leagues-h2h/{id}/standings/` | H2H league standings |

---

### Not Implemented (by design)

- **Push notifications** — APNs/FCM/local notifications
- **Monetisation** — No IAP, subscriptions, or payments
- **Predicted lineups** — Requires third-party APIs
- **Rise/fall tonight** — Not reliably computable from official data
- **Cup bracket** — Official API endpoint lacks structured bracket data
- **Overall live rank** — Would require crawling millions of entries; not feasible
- **Cloud sync** — No auth system; local persistence only
