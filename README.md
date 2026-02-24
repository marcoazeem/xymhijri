# XYM Hijri Calendar

A Flutter Hijri calendar app with a modern RTL interface, Arabic and Dhivehi typography, holiday listing, and Excel export.

## Features

- Hijri month calendar grid with selectable days
- Dual date display:
  - Main Hijri date in Arabic numerals/text
  - Small Gregorian day number in English numerals
- Dhivehi weekday and month labels (RTL)
- Holiday panel for the selected Hijri month
- Month navigation (previous/next)
- Jump to today
- Hijri date offset controls (`- / +`)
- Export Hijri calendar to `.xlsx` and share

## Fonts

The app uses custom script-specific fonts:

- Arabic: `KfgqpcUthmanic` (`assets/KFGQPC Uthmanic Script HAFS Regular.otf`)
- Dhivehi: `Faseyha` (`assets/faseyha.ttf`)

## Tech Stack

- Flutter (Dart SDK `^3.10.4`)
- [`hijri`](https://pub.dev/packages/hijri)
- [`excel`](https://pub.dev/packages/excel)
- [`path_provider`](https://pub.dev/packages/path_provider)
- [`share_plus`](https://pub.dev/packages/share_plus)

## Getting Started

### Prerequisites

- Flutter SDK installed
- A configured device/emulator/simulator

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

## Notes

- If you change asset fonts, do a full restart (not only hot reload).
- `share_plus` deprecation hints may appear in analyzer output; they are currently informational.

## Project Structure

- `lib/main.dart` - main app UI and calendar logic
- `assets/` - custom Arabic and Dhivehi fonts
