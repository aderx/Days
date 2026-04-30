# Days

Days is a lightweight macOS menu bar calendar focused on fast date checking and China mainland holiday visibility.

## MVP

- Menu bar date with configurable fields: icon, year, month, day, weekday.
- Chinese date units in menu bar labels, for example `2026年04月29日` or `04月29日`.
- Large month grid with selected date, today marker, holidays, workday adjustments, and observances.
- "Today" shortcut after changing dates or months.
- Project-local Nothing Design skill at `.codex/skills/nothing-design`.
- Holiday seed and sync support through the iCloud China holidays ICS feed.

## Deferred

- macOS Calendar events.
- macOS Reminders.
- Full day detail editing.
- Custom app icon/logo.

## License

MIT. You can use, copy, modify, publish, distribute, sublicense, and sell copies under the terms in `LICENSE`.

## Fonts

The Nothing Design skill recommends Doto, Space Grotesk, and Space Mono. This native macOS MVP currently uses SF Pro and SF Mono fallbacks through SwiftUI system fonts. To use the exact Google font stack later, add the `.ttf` files to the app target and register them in the generated Info.plist.
