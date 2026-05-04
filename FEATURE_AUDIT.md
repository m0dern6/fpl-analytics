# FPL Analytics — Feature Audit Matrix

> Generated: May 2026  
> Tech stack: Flutter (Dart) · Provider · HTTP · SharedPreferences

---

## Legend
| Status | Meaning |
|--------|---------|
| ✅ Implemented | Feature is fully working |
| 🔶 Partial | Exists but incomplete or has known gaps |
| ❌ Missing | Not yet implemented |

---

## A) Onboarding + Team Linking

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Guest mode with sample data | ❌ Missing | No sample/demo data path | — |
| Link by Entry/Team ID | ✅ Implemented | `FplTeamScreen` saves ID to SharedPreferences | `screens/fpl_team_screen.dart` |
| Multiple saved profiles + quick-switch | 🔶 Partial | `UserTeamsProvider` saves local teams but no FPL-entry-linked profiles | `providers/user_teams_provider.dart` |
| Streamer mode (hide entry ID/name) | ❌ Missing | — | — |
| Local time-zone aware deadlines | 🔶 Partial | `formatDateTime` converts to local, no explicit timezone display | `utils/formatters.dart` |
| Cloud sync | ❌ Missing | Local only (intentional; no auth system added) | — |
| Onboarding screen flow | ❌ Missing | App opens directly to Dashboard | — |

## B) Home Dashboard

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Deadline countdown | 🔶 Partial | GW badge shown; no live countdown timer | `screens/dashboard_screen.dart` |
| Current GW state + timestamps | ✅ Implemented | GW badge, finished/active/next labels | `screens/dashboard_screen.dart` |
| "My Team" snapshot (XI + bench + C/VC) | 🔶 Partial | Shows picks if entry ID saved; no C/VC highlight | `screens/fpl_team_screen.dart` |
| Bank, team value, free transfers | 🔶 Partial | Entry data fetched; some fields displayed | `screens/fpl_team_screen.dart` |
| Flagged players summary | ❌ Missing | No injury summary on dashboard | — |
| Action shortcuts (transfer plan, captain picker) | ❌ Missing | — | — |
| Price changes since yesterday | ❌ Missing | No daily snapshot comparison | — |

## C) Player Database

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Player list with search | ✅ Implemented | Substring search on name | `screens/players_screen.dart` |
| Filter: position, team | ✅ Implemented | Position chips + team dropdown | `screens/players_screen.dart` |
| Filter: price, ownership, minutes, form | 🔶 Partial | Sort by these fields; no price range filter | `screens/players_screen.dart` |
| Sort: projected pts, value, form, points | ✅ Implemented | 6 sort options | `screens/players_screen.dart` |
| Saved filter presets | ❌ Missing | — | — |
| Player profile: price + ownership history | 🔶 Partial | Shows current price/ownership; no history chart (stored from install) | `screens/player_detail_screen.dart` |
| GW-by-GW points and minutes | ✅ Implemented | History tab in player detail | `screens/player_detail_screen.dart` |
| Expected stats (xG/xA from API) | ✅ Implemented | Displayed when API provides them | `screens/player_detail_screen.dart` |
| Fixture + projections table | 🔶 Partial | Fixtures shown; projections use internal model | `screens/player_detail_screen.dart` |
| Comparable players | ❌ Missing | — | — |
| Watchlist | ❌ Missing | — | — |
| Long-press quick actions | ❌ Missing | — | — |
| Player notes | ❌ Missing | — | — |
| Recently viewed players | ❌ Missing | — | — |

## D) Team/Club Database

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Team list | ✅ Implemented | All 20 clubs | `screens/teams_screen.dart` |
| Team fixtures | ✅ Implemented | `TeamFixturesScreen` | `screens/team_fixtures_screen.dart` |
| Home/away splits | ❌ Missing | API doesn't provide aggregate home/away stats | — |
| Fixture run visual (FDR) | ✅ Implemented | `FixtureDifficultyScreen` | `screens/fixture_difficulty_screen.dart` |

## E) Fixtures & Calendar

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Fixture list | ✅ Implemented | All fixtures | `screens/fixtures_screen.dart` |
| Fixture ticker with GW range | 🔶 Partial | GW filter exists; no multi-GW range slider | `screens/fixtures_screen.dart` |
| Difficulty color modes | ✅ Implemented | Official FDR colors | `widgets/difficulty_badge.dart` |
| Blank/DGW tracker | 🔶 Partial | Derivable from fixture data; no dedicated view | — |
| Fixture detail view | ✅ Implemented | `FixtureDetailScreen` | `screens/fixture_detail_screen.dart` |
| Add-to-calendar | ❌ Missing | Platform calendar integration not implemented | — |

## F) Analytics / Projections Engine

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Points projection model (official fields only) | ✅ Implemented | `computePlayerScore` / `_computeScore` | `providers/fpl_provider.dart` |
| Projected points per player (1/3/5/8 GW horizon) | 🔶 Partial | Single-GW; no multi-GW horizon breakdown | `providers/fpl_provider.dart` |
| Confidence indicator | ❌ Missing | No High/Med/Low label | — |
| Explainability ("why rated highly") | ❌ Missing | Score factors not surfaced to UI | — |

## G) Transfer Tools

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Transfer Planner multi-week | ❌ Missing | — | — |
| Bank tracking + sell value | 🔶 Partial | Entry bank shown; sell price calc added in `fpl_rules.dart` | `logic/fpl_rules.dart` |
| FT banking rules (max 5) | ✅ Implemented | Pure function in `fpl_rules.dart` with tests | `logic/fpl_rules.dart` |
| Hits calculation | ✅ Implemented | Pure function in `fpl_rules.dart` with tests | `logic/fpl_rules.dart` |
| Save multiple plans | ❌ Missing | — | — |
| Lock players | ❌ Missing | — | — |
| Replacement finder | ❌ Missing | — | — |
| What-if simulator | ❌ Missing | — | — |

## H) Chip Tools

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Chip availability tracker | 🔶 Partial | Read from entry data; not surfaced prominently | `screens/fpl_team_screen.dart` |
| Wildcard draft builder | 🔶 Partial | `AiPickMode.wildcard` in AI picks | `providers/fpl_provider.dart` |
| Free Hit draft | 🔶 Partial | `AiPickMode.freeHit` in AI picks | `providers/fpl_provider.dart` |
| Bench Boost checker | 🔶 Partial | `AiPickMode.benchBoost` in AI picks | `providers/fpl_provider.dart` |
| Triple Captain hub | 🔶 Partial | `AiPickMode.tripleCaptain` in AI picks | `providers/fpl_provider.dart` |
| Side-by-side chip comparison | ❌ Missing | — | — |

## I) Captaincy + Lineup

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Captain ranker for next GW | ✅ Implemented | AI picks / best XI computes captain | `providers/fpl_provider.dart` |
| Vice-captain suggestions | ✅ Implemented | Second in scoring rank | `providers/fpl_provider.dart` |
| Starting XI picker with formation checks | 🔶 Partial | `TeamBuilderScreen` exists; formation legality partial | `screens/team_builder_screen.dart` |
| Bench order optimization | 🔶 Partial | Bench order displayed; no auto-optimize | — |
| "Early kickoff risk" indicator | ❌ Missing | — | — |

## J) Live GW Center

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Live points for my entry | 🔶 Partial | Live data loaded; not aggregated per entry picks | `providers/fpl_provider.dart` |
| Live event feed (goals/assists/CS) | 🔶 Partial | Live endpoint fetched; not surfaced as feed | `screens/gameweek_detail_screen.dart` |
| Predicted auto-subs (captain/vice resolution) | ✅ Implemented | Pure functions in `fpl_rules.dart` | `logic/fpl_rules.dart` |
| Bonus points (BPS live) | 🔶 Partial | Live endpoint includes BPS; show raw value | — |
| Live mini-league standings | ❌ Missing | — | — |
| Rival comparison cards | ❌ Missing | — | — |
| Clear labeling of unavailable metrics | ✅ Implemented | Architecture doc + UI copy planned | — |

## K) Price / Value Center

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Actual price changes since last snapshot | ❌ Missing | No daily snapshot stored | — |
| My team value trend | ❌ Missing | No time-series storage | — |
| Watchlist price changes | ❌ Missing | — | — |
| Rise/fall tonight | ❌ Missing | Intentionally omitted — not supportable from official API without crawling | — |

## L) News / Availability

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Injury/flag tracker (official status + news) | ✅ Implemented | Player card shows status dot; detail shows news | `widgets/player_card.dart`, `screens/player_detail_screen.dart` |
| My squad flags overview | 🔶 Partial | Available in FPL team screen; no dedicated tab | `screens/fpl_team_screen.dart` |
| No external news sources | ✅ Implemented | Official API only | — |

## M) Leagues + Rivals

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Classic league standings | ✅ Implemented | `LeagueDetailScreen` | `screens/league_detail_screen.dart` |
| H2H leagues | 🔶 Partial | Endpoint added; no dedicated H2H screen | `services/fpl_service.dart` |
| Cup bracket view | ❌ Missing | Omitted — official API cup endpoint structure incomplete | — |
| Rival comparison | ❌ Missing | — | — |
| Shareable comparison card | ❌ Missing | — | — |

## N) Review & Learning

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Post-GW report (bench points, captaincy outcome) | 🔶 Partial | Gameweek detail shows scores; no dedicated review | `screens/gameweek_detail_screen.dart` |
| Season review (chip usage, hit count) | ❌ Missing | — | — |
| Decision journal | ❌ Missing | — | — |

## UX Micro-Features

| Feature | Status | Notes | Module |
|---------|--------|-------|--------|
| Global search | 🔶 Partial | Per-screen search only | — |
| Recently viewed players | ❌ Missing | — | — |
| Long-press quick actions | ❌ Missing | — | — |
| Dark mode | ✅ Implemented | `ThemeProvider` + `AppTheme` | `providers/theme_provider.dart` |
| Loading skeletons (shimmer) | ✅ Implemented | `LoadingWidget` with shimmer | `widgets/loading_widget.dart` |
| Empty states | 🔶 Partial | Some screens have empty state copy | — |
| Pull-to-refresh | ✅ Implemented | All major screens | — |
| "Last updated" timestamps | ❌ Missing | No timestamp display | — |
| Offline banner | ❌ Missing | — | — |
| Share sheets | ❌ Missing | — | — |
| Streamer mode | ❌ Missing | — | — |

---

## Summary

| Count | Status |
|-------|--------|
| 27 | ✅ Implemented |
| 24 | 🔶 Partial |
| 28 | ❌ Missing |

**Key priorities addressed in this update:**
1. Rule logic pure functions + unit tests (`lib/logic/fpl_rules.dart`)
2. Live GW Center tab
3. Leagues tab in bottom nav
4. Transfer Planner screen
5. Onboarding / entry linking flow
6. Offline caching + banner
7. Deadline countdown on Dashboard
8. Architecture + How-to-run documentation
