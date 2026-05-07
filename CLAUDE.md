# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter Hijri calendar app (`xymhijri`). Single-screen UI with RTL layout, Arabic + Dhivehi typography, holiday list, and Excel export. Dart SDK `^3.10.4`.

## Common commands

```bash
flutter pub get            # install dependencies
flutter run                # run on the currently selected device
flutter run -d <device>    # run on a specific device (see `flutter devices`)
flutter analyze            # static analysis / lint
flutter test               # run all tests
flutter test test/widget_test.dart --plain-name "<name>"   # single test
flutter build apk          # release builds: also ios / macos / web / windows / linux
```

If asset fonts (`assets/*.otf`, `assets/*.ttf`) change, do a full restart — hot reload does not pick up new font files.

## Architecture

Most app logic lives in `lib/main.dart`; pure date math is extracted to `lib/hijri_date.dart`.

- **`HijriCalendarApp`** — `MaterialApp` root, sets the cream theme and points at `CalendarPage`. `main()` calls `HijriCalendar.setLocal('ar')` once before runApp.
- **`_CalendarPageState`** — owns all state: `_currentYear`/`_currentMonth`/`_selectedDay` (Hijri), `_offset` (manual day correction applied to every Hijri↔Gregorian conversion, persisted via `shared_preferences` under key `hijri_offset`), `_isExporting`. Also owns the static `_holidays` map (keyed `"<hMonth>/<hDay>"`), Arabic month names, and Dhivehi weekday/Gregorian-month name lists.
- **Hijri ↔ Gregorian conversion** — top-level pure functions in `lib/hijri_date.dart`: `hijriToGregorianWithOffset(year, month, day, offset)` and `hijriMonthLength(year, month, offset)`. `_CalendarPageState` exposes thin wrappers that pass `_offset`. Keep these pure so they remain unit-testable.
- **Offset persistence** — `_loadOffset` runs from `initState` (async); `_changeOffset(delta)` is the only mutator and writes through to `SharedPreferences`. Don't `setState(() => _offset = ...)` directly — go through `_changeOffset` so persistence stays consistent.
- **Grid model** — `_buildMeta()` produces a fixed 6×7 = 42-cell grid as `_CalendarCellData` (Hijri y/m/d, derived `gDate`, `inCurrentMonth`). Sunday is treated as the first column (`weekday == DateTime.sunday → 0`); leading cells come from the previous Hijri month, trailing cells from the next. The `build()` method recomputes meta on every frame.
- **Excel export** — `_exportToExcel` builds a 12-month grid (3 cols × 4 rows of month blocks, each `8 wide × 9 tall`) using the `excel` package, writes to a temp file via `path_provider`, then shares via `share_plus` (`Share.shareXFiles`). It uses the same `_offset`-aware conversion as the on-screen grid.
- **Typography helpers** — `_arabicStyle` (bundled `Hafs` from `assets/hafs.ttf`, with OpenType `rlig`/`liga`/`calt`/`mark`/`mkmk` features enabled for traditional Quranic shaping), `_dhivehiStyle` (bundled `Faseyha` from `assets/faseyha.ttf`), and `_toArabicNum` for Eastern Arabic numerals. Use these rather than ad-hoc `TextStyle`s when adding Arabic/Dhivehi text.
- **Layout** — the page is wrapped in `Directionality(rtl)`; `_buildHolidaysPanel` re-asserts RTL for safety. Top strip → month selector card → weekday header → grid (`Expanded`) → holidays panel → offset controls.

### Conventions when editing

- Keep all Hijri↔Gregorian conversions going through `hijriToGregorianWithOffset` (or its instance wrapper) so `_offset` is honored everywhere (on-screen grid, selected-day strip, and Excel export).
- Holiday keys are `"<hMonth>/<hDay>"` (no year). Adding a holiday means one entry in `_holidays` with `en` and `ar` strings; the panel and red coloring in the grid pick it up automatically.
- The grid's weekend coloring uses raw column index (`colIndex == 5 || 6` → Friday/Saturday in this Sunday-first layout), independent of the holiday map.
- Widget tests must call `SharedPreferences.setMockInitialValues(...)` in `setUp` so `_loadOffset` doesn't hit a missing platform channel.

## Caveats

- `share_plus` and `withOpacity` may emit deprecation infos under `flutter analyze`; they are informational and pre-existing.
- `assets/KFGQPC Uthmanic Script HAFS Regular.otf` and `assets/al_mushaf.ttf` are no longer registered in `pubspec.yaml` (replaced by `assets/hafs.ttf`). The files are harmless on disk; delete if you want to slim the repo.

## Graphify (per-user global rule)

A graphify knowledge graph at `graphify-out/` may exist (from the user's global CLAUDE.md). If it does: read `graphify-out/GRAPH_REPORT.md` before architecture questions, prefer `graphify query/path/explain` over grep for cross-module questions, and run `graphify update .` after editing code files. If `graphify-out/` is absent, ignore.
