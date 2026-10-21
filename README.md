# World Time

A macOS (Sonoma 14+) menu bar clock showing local time plus up to 5 more cities.

- Menu bar shows local day, date and time (each part can be toggled)
- Popover lists local time and up to 5 cities, each with day/date, zone abbreviation, UTC offset,
  difference from local time, and "Tomorrow"/"Yesterday" when the day differs
- 12-hour / 24-hour clock, optional seconds
- Launch at login (via `SMAppService`)
- English and Traditional Chinese (繁體中文): pick a language in the popover, or choose "System" to
  follow macOS (including the per-app language in System Settings › General › Language & Region).
  Dates, weekdays, AM/PM, city and country names, and the Launchpad name (世界時間) are all translated
- In Chinese, each clock also shows its Chinese lunar date (農曆), e.g. 丙午（馬）年八月廿八, with an
  option to show it in the menu bar, labeled 農曆 (e.g. 10月21日 · 農曆九月初十  14:32)
- Daylight saving: cities are stored by IANA time zone ID, so offsets come from macOS's time zone
  database for each instant. A **DST** badge shows when a zone is on summer time, and a notice
  appears up to 14 days before its clocks change. The clock also refreshes immediately when the
  system time zone, clock or day changes, or the Mac wakes from sleep.

## Build

```sh
./build.sh            # builds "build/World Time.app"
./build.sh --install  # also copies it to /Applications (so it appears in Launchpad) and launches it
```

Only the Command Line Tools are needed (no Xcode). It must be in `/Applications` before turning on
"Launch at login".

Right-click a city to reorder or remove it. Hover over it to show a remove button.

## Translations

UI text uses the English string as the key, looked up via `L("…")`.

- `Resources/zh-Hant.lproj/Localizable.strings`: interface text
- `Resources/zh-Hant.lproj/Cities.strings`: Chinese names for cities that share another city's time
  zone (e.g. San Francisco). Cities with their own zone ID get their names from macOS automatically.
- `Resources/*/InfoPlist.strings`: the app name shown in Finder and Launchpad
