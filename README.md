# World Time

A macOS (Sonoma 14+) menu bar clock showing local time plus up to 5 more cities.

- Menu bar shows local day, date and time (each part can be toggled)
- Popover lists local time and up to 5 cities, each with day/date, zone abbreviation, UTC offset,
  difference from local time, and "Tomorrow"/"Yesterday" when the day differs
- 12-hour / 24-hour clock, optional seconds
- Launch at login (via `SMAppService`)
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
