# Assumptions

This document records design decisions and assumptions made during the implementation of the FPL Analytics companion app where the official spec or API is ambiguous.

---

## Data Layer

1. **Official API only.** All data is sourced exclusively from `https://fantasy.premierleague.com/api/`. No third-party services, scraping, or paid APIs are used.

2. **Bootstrap TTL = 5 minutes in-memory, 1 hour on-disk.** The bootstrap-static endpoint is relatively stable within a gameweek. A 5-minute in-memory cache and 1-hour disk cache are used to balance freshness with rate-limiting courtesy.

3. **Fixtures TTL = 30 minutes.** Fixture data changes slowly; 30 minutes is a reasonable disk cache.

4. **Player summary TTL = 15 minutes.** Player summaries (history, upcoming fixtures) are per-player; 15 minutes is sufficient.

5. **Live GW TTL = 2 minutes.** During a live gameweek, scores can update frequently. The 2-minute cache is a balance between freshness and API courtesy.

6. **Entry picks TTL = 10 minutes.** Picks are fixed once a deadline passes; for the current GW before deadline, they can change.

---

## Rule Logic

7. **Sell price formula.** Following official FPL rules: `sell_price = purchase_price + floor((current_price - purchase_price) / 2)` when `current_price > purchase_price`; otherwise `sell_price = current_price`. All values in tenths of millions (integers). Source: official FPL help pages.

8. **Free transfers.** A manager starts with 1 free transfer. Unused free transfers roll over, up to a configured maximum. The API's `game_settings.league_join_private_max` and `game_settings.transfers_sell_on_free` provide context; the max banked FTs defaults to **5** (current FPL rule as of 2024/25 season) if not available from game settings.

9. **Hits.** Each transfer beyond the free allowance costs 4 points. A wildcard or free-hit chip removes this deduction.

10. **Captain/vice-captain logic.** If the captain played 0 minutes, the vice-captain is awarded double points instead. "Played 0 minutes" means `minutes == 0` in the live data AND the fixture has started (i.e., at least one player in the game has minutes > 0).

11. **Auto-substitution order.** Auto-subs obey bench priority (slot 12, 13, 14 for outfield; slot 11 for GK). A substitute is eligible if: (a) they played > 0 minutes, (b) the sub does not violate the minimum formation requirement (1 GK, 3 DEF, 2 MID, 1 FWD as minimums). The GK substitute only replaces the starting GK.

12. **Chip availability.** Chip availability is read from the entry's `active_chip` and history. If the API does not return a `chip_plays` breakdown, we assume standard season rules: wildcard available once in each half of the season, free hit once, bench boost once, triple captain once.

13. **Bench Boost.** All bench players score points normally (no auto-sub needed; all 15 play). Captain/vice still applies.

14. **Free Hit.** For scoring purposes, treat the free hit squad as the live squad for that GW; on the next GW the original squad is restored.

---

## Projections Engine

15. **No third-party xG/xA data.** The app uses only the `expected_goals` and `expected_assists` fields from the official API (which are official Opta data provided by FPL). These are labeled as "Official expected stats" in the UI.

16. **Projection transparency.** Every projected points figure is labeled "Model-based estimate" with a tooltip explaining the inputs (form, PPG, ICT, FDR, availability).

17. **"Rise/fall tonight" not implemented.** Official API does not provide next-price-change predictions in a reliable way. The feature is omitted with a clear "Unavailable from official API" message.

---

## Navigation

18. **Bottom tab structure.** Five tabs: Home, Players, Plan, Live, Leagues. The existing Leaders and Analytics tabs are merged into "Plan" (analytics tools) and "Leagues" as the spec requires.

---

## Offline Mode

19. **Offline detection.** The app uses `connectivity_plus` to detect network status. When offline, the app shows last cached data with a sticky banner: "Offline — showing cached data from [timestamp]."

20. **No cloud sync.** Local persistence only (SharedPreferences). Cloud sync is explicitly out of scope per requirements.

---

## Monetisation & Notifications

21. **No monetisation.** No IAP, subscriptions, or payment flows exist or will be added.

22. **No push notifications.** No APNs, FCM, or local notification code exists or will be added.

---

## Accessibility

23. **Dynamic text sizing.** The app uses Flutter's default text scaling. All text sizes are specified in `sp`-equivalent logical pixels responsive to system font size.

24. **Colorblind-safe palettes.** Difficulty colors use a hue-independent scale (green→yellow→red) with shape/number redundancy. Position colors are distinct under common colorblindness simulations.

25. **Semantic labels.** Key interactive elements include `Semantics` wrappers or `tooltip` strings for VoiceOver/TalkBack support.
