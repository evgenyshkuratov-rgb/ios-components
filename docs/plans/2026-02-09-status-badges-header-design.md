# Status Badges Header

## Problem

The GalleryApp has no visibility into the broader design system — developers can't see at a glance how many icons, colors, or components exist without leaving the app.

## Solution

Add a horizontal row of three pill-shaped badges at the top of `ComponentListVC`, showing live counts fetched from GitHub raw URLs.

## Visual layout

```
┌─────────────────────────────────────┐
│  [Components: 1] [Icons: 117] [Colors: 119]  │
│─────────────────────────────────────│
│  ChipsView                        > │
│  Filter chips with Default, ...     │
└─────────────────────────────────────┘
```

## Pill design

- Rounded rect background using `UIColor.secondarySystemBackground`
- SF Symbol icon + label + count (e.g. "Components: 1")
- Small/caption font size
- Arranged in a horizontal `UIStackView`
- Placed in the table's `tableHeaderView`

## Data sources

| Category   | URL                                                                                  | JSON field       |
|------------|--------------------------------------------------------------------------------------|------------------|
| Components | `raw.githubusercontent.com/evgenyshkuratov-rgb/ios-components/main/specs/index.json` | `components` array count |
| Icons      | `raw.githubusercontent.com/evgenyshkuratov-rgb/icons-library/main/metadata.json`     | `icons` array count      |
| Colors     | `raw.githubusercontent.com/evgenyshkuratov-rgb/icons-library/main/colors.json`       | `colors` array count     |

## Data flow

1. On `viewDidLoad`, show pills with placeholder "..." text
2. Fire three parallel `URLSession` requests to GitHub raw URLs
3. Parse JSON, extract array counts, update pill labels on main thread
4. If a request fails, show dash instead of count (no error alerts)

## Interaction

None — pills are purely informational for now. Tappable drill-down can be added later.

## Decisions

- No caching — fetches on every launch (gallery app, not production)
- No loading spinners — placeholder text is sufficient
- No error states beyond showing dash
- iOS 14+ compatible (no async/await, use completion handlers)
