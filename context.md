# iOS Components Library

## What is this?

UIKit component library for rapid prototyping with LLM-friendly JSON specs. Components are polished and near-production quality, designed for developers to reference and adapt. An MCP server provides Claude Code with direct access to component specifications.

**GitHub repo:** https://github.com/evgenyshkuratov-rgb/ios-components

## Design System Rules (MANDATORY)

> **STRICT RULE: Every component and the GalleryApp interface MUST use ONLY icons and colors from the connected icons-library, and ONLY Roboto text styles from `DSTypography`. No SF Symbols, no hardcoded hex colors, no system colors, no custom font sizes or weights. Zero exceptions.**

### Icons — ONLY from icons-library

- Use `list_icons` MCP tool to browse all 276 available icons (6 categories)
- Use `get_icon` MCP tool to get SVG data for a specific icon by kebab-case name
- **NEVER** use `UIImage(systemName:)` (SF Symbols) — always use icons-library assets
- **NEVER** create or inline custom icons — if an icon is missing, flag it and request it be added to the icons-library
- Load icons from the icons-library SVG assets at runtime or bundle them from the local clone

### Colors — ONLY from icons-library color tokens

- Use `list_colors` MCP tool to browse all 157 color tokens (5 brands, Light/Dark modes)
- **NEVER** hardcode hex values like `UIColor(red:green:blue:)` — always reference a named token
- **NEVER** use `UIColor.systemGreen`, `.label`, `.secondaryLabel`, or any Apple system color
- Use the **Frisbee** brand as the default (Light/Dark)
- Key tokens (Frisbee brand):
  - **Background/01 Base**: `#FFFFFF` / `#1A1A1A` — primary screen background
  - **Background/02 Second**: `#F5F5F5` / `#313131` — cards, secondary surfaces, input fields
  - **Background/Sheet or Modal**: `#FFFFFF` / `#232325` — modals, bottom sheets
  - **Basic Colors/100%**: primary text (black in light mode)
  - **Basic Colors/50%**: secondary/subtitle text
  - **Basic Colors/30%**: placeholder text, disabled states
  - **Basic Colors/10%**: borders, thin separators
  - **Basic Colors/6%**: subtle backgrounds, hover states
  - **System/Success Default**: green accent for CTAs and positive actions
  - **System/Danger Default**: `#E06141` — destructive actions, errors
  - **System/Warning Default**: caution states
  - **White/100%**: text on colored buttons
  - **ThemeFirst/Primary/Default**: brand accent where theme color is needed

### Design Principles (from reference designs)

These visual rules apply to **all components and GalleryApp screens**:

#### Spacing
- **Horizontal padding**: 16pt (leading and trailing, consistent on every screen)
- **Vertical section spacing**: 24pt between major sections
- **List item vertical spacing**: 12pt between rows
- **Chip/pill gap**: 8pt between adjacent chips
- **Inner content padding**: 16pt inside cards

#### Corner Radii
- **Buttons (full-width CTA)**: 16pt corner radius, capsule feel
- **Cards and content containers**: 16pt
- **Input fields**: 12pt
- **Chips and pills**: full-height capsule (height / 2)
- **App-icon-style thumbnails**: 16pt (squircle)
- **Circular avatars**: full circle (width / 2)

#### Typography (Roboto)
All text MUST use **Roboto** font family. Only styles defined in `DSTypography` are allowed — no custom sizes or weights.

- **Font files**: `Roboto.ttf` + `RobotoMono.ttf` (variable) bundled in `Resources/Fonts/`
- **22 main styles**: Title 1–7 (20–32pt), Subtitle 1–2 (18pt), Body 1–5 (14–16pt), Subhead 1–4 (13–14pt), Caption 1–3 (11–12pt), Subcaption (11pt)
- **15 bubble styles**: For chat messages — Roboto + Roboto Mono, sizes 13–24pt
- **Usage**: `label.font = DSTypography.title1B.font` (simple) or `DSTypography.title1B.apply(to: label)` (full fidelity with line height + letter spacing)
- **In Components package**: Use `ChipsView.robotoFont(size:weight:)` helper (Roboto with system font fallback)

#### Visual Patterns
- **Navigation bar**: Back arrow icon (from icons-library `arrow-left` or `back-ios`) on leading side, action icons on trailing side — no text back buttons
- **Filter chips**: Capsule-shaped, 1pt border using Basic Colors/10%, selected state uses filled background
- **Cards**: White background (Background/01 Base) with subtle 1pt border or soft shadow, 16pt corners
- **Full-width buttons**: 16pt corner radius, System/Success Default green for primary CTAs, Semibold white text
- **Lists**: Left avatar/icon (48–56pt) + text stack (title bold + subtitle gray) + trailing value, thin separator using Basic Colors/6%
- **Floating action button**: Capsule pill shape, System/Success Default green, centered white text, positioned at bottom center with 24pt bottom margin
- **Profile screens**: Centered circular avatar, bold name below, gray handle, horizontal tab chips
- **Detail screens**: Centered large icon (80–120pt), title below, key-value metadata pairs, description card with Background/02 Second, full-width CTA at bottom

## Project structure

```
ios-components/
├── context.md                    # This file - project overview for LLMs
├── Package.swift                 # Swift Package manifest (iOS 14+)
├── README.md                     # Setup instructions for team
├── .gitignore                    # Build artifacts, node_modules, etc.
│
├── Sources/
│   └── Components/
│       └── ChipsView.swift       # Filter chip component
│
├── specs/
│   ├── index.json                # Component index for list_components
│   └── components/
│       └── ChipsView.json        # Full ChipsView specification
│
├── GalleryApp/
│   ├── GalleryApp.xcodeproj/     # Xcode project (includes "Sync Design System Counts" build phase)
│   └── GalleryApp/
│       ├── AppDelegate.swift     # App entry point, nav bar appearance config
│       ├── ComponentListVC.swift # Wise-inspired catalog (brand circle, search bar, icon cards)
│       ├── DesignSystem/
│       │   ├── DSBrand.swift     # 5-brand enum (Frisbee/TDM/Sover/KCHAT/Sense New) → ChipsColorScheme
│       │   ├── DSColors.swift    # Dynamic light/dark color tokens (from icons-library)
│       │   ├── DSTypography.swift # Roboto text styles from Figma (37 styles)
│       │   ├── DSSpacing.swift   # Spacing & corner radius tokens
│       │   ├── DSIcon.swift      # Runtime SVG→UIImage renderer
│       │   └── SVGPathParser.swift # Bezier path parser for SVG <path> elements
│       ├── Previews/
│       │   └── ChipsViewPreviewVC.swift  # Interactive preview with state/size/theme/brand controls
│       ├── Resources/
│       │   ├── Info.plist
│       │   ├── Icons/            # Bundled SVG icon files from icons-library
│       │   ├── Fonts/            # Roboto & Roboto Mono variable fonts
│       │   │   ├── Roboto.ttf
│       │   │   └── RobotoMono.ttf
│       │   └── design-system-counts.json  # Auto-generated by build phase
│
├── mcp-server/
│   ├── package.json              # npm package config
│   ├── index.js                  # MCP server with 4 tools
│   └── README.md                 # MCP setup instructions
│
├── scripts/
│   ├── statusline-command.sh              # Claude Code status line (context window bar)
│   └── sync-design-system-counts.sh       # Build phase script: counts + timestamps
│
└── docs/
    └── plans/
        ├── 2026-02-05-ios-components-library-design.md
        ├── 2026-02-09-team-sync-awareness-design.md
        ├── 2026-02-09-team-sync-awareness-implementation.md
        └── 2026-02-09-interactive-chips-preview.md
```

## Available components

| Component | Description | States |
|-----------|-------------|--------|
| ChipsView | Filter chip with injectable theming (`ChipsColorScheme`), icon/text/avatar variants, Figma-exact layout | Default, Active, Avatar |

### ChipsView Architecture

**Injectable theming** via `ChipsColorScheme` struct (in the Components package):
```swift
public struct ChipsColorScheme {
    public let backgroundDefault: UIColor   // Basic Colors/8%
    public let backgroundActive: UIColor    // ThemeFirst/Primary/Default
    public let textPrimary: UIColor         // Basic Colors/90%
    public let closeIconTint: UIColor       // Basic Colors/50%
}
```

**Two configure methods:**
- `configure(text:icon:state:size:colorScheme:)` — for Default and Active states
- `configureAvatar(name:avatarImage:closeIcon:size:colorScheme:)` — for Avatar state (close icon injected, no SF Symbols)

**Sizes:** `.small` (32pt) and `.medium` (40pt) with Figma-exact padding per state/size.

**Brand theming** via `DSBrand` enum in GalleryApp (5 brands):
| Brand | Accent Light | Accent Dark |
|-------|-------------|-------------|
| Frisbee | `#40B259` | `#40B259` |
| TDM | `#3E87DD` | `#3886E1` |
| Sover | `#C7964F` | `#C4944D` |
| KCHAT | `#EA5355` | `#E9474E` |
| Sense New | `#7548AD` | `#7548AD` |

Use `DSBrand.frisbee.chipsColorScheme(for: .light)` to get a themed `ChipsColorScheme`.

## Adding a new component

1. **Create Swift file**: `Sources/Components/NewComponent.swift`
2. **Create JSON spec**: `specs/components/NewComponent.json`
3. **Update index**: Add entry to `specs/index.json`
4. **Add preview**: `GalleryApp/GalleryApp/Previews/NewComponentPreviewVC.swift`
5. **Update list**: Add to `ComponentListVC.components` array
6. **Test**: Run GalleryApp in simulator
7. **Push**: Changes sync to MCP automatically via GitHub raw URLs

## JSON spec format

### specs/index.json (lightweight index)
```json
{
  "version": "1.0.0",
  "components": [
    {
      "name": "ChipsView",
      "description": "Filter chip with Default, Active, and Avatar states"
    }
  ]
}
```

### specs/components/*.json (full specification)
```json
{
  "name": "ChipsView",
  "description": "Full description of the component",
  "import": "import Components",
  "properties": [
    {
      "name": "text",
      "type": "String",
      "description": "The text displayed in the chip"
    }
  ],
  "usage": "let chip = ChipsView()\nchip.configure(text: \"Filter\", state: .default, size: .small)",
  "tags": ["chips", "filter", "tag"]
}
```

## MCP Server

Four tools available:

| Tool | Description |
|------|-------------|
| `list_components` | Returns all components with brief descriptions (fetches from GitHub raw URLs) |
| `get_component` | Returns full spec for a component by name (fetches from GitHub raw URLs) |
| `search_components` | Search by keyword in name/description/tags (fetches from GitHub raw URLs) |
| `check_updates` | Runs `git fetch` + compares `main..origin/main` to show new/modified Sources/ and specs/ files with commit messages |

### Claude Code config (~/.claude.json)
```json
{
  "mcpServers": {
    "ios-components": {
      "type": "stdio",
      "command": "node",
      "args": ["/path/to/ios-land-component/mcp-server/index.js"]
    }
  }
}
```

### Setup
```bash
cd mcp-server && npm install
```

## Swift Package usage

```swift
// Package.swift dependency
.package(url: "https://github.com/evgenyshkuratov-rgb/ios-components.git", from: "1.0.0")

// In code
import Components

// Default/Active state with injectable color scheme
let chip = ChipsView()
chip.configure(
    text: "Filter option",
    icon: myIcon,
    state: .active,
    size: .medium,
    colorScheme: ChipsColorScheme(
        backgroundDefault: myBgColor,
        backgroundActive: myAccentColor,
        textPrimary: myTextColor,
        closeIconTint: mySecondaryColor
    )
)
chip.onTap = { print("Tapped") }

// Avatar state with close icon (no SF Symbols)
let avatarChip = ChipsView()
avatarChip.configureAvatar(
    name: "Имя",
    avatarImage: avatarImg,
    closeIcon: closeImg,
    size: .small,
    colorScheme: .default  // Frisbee Light fallback
)
avatarChip.onClose = { print("Removed") }
```

## GalleryApp

Xcode project for browsing and testing components. Design is **Wise-inspired** — clean, spacious, and authentic. Main screen has a **hidden nav bar** with content rendered in a scroll view:

1. **Frisbee logo** (44pt height, original green `#11D16A`, rendered via `DSIcon.coloredNamed`) — top-left branding element
2. **Large bold title** "Components Library" (`title1B`, 32pt)
3. **Status line** (e.g., `1 Component (3d) · 276 Icons (1h) · 157 Colors (1h)`) in `subhead3R` tertiary color
4. **Search bar** (`SearchBarView` — functional UITextField, 48pt height, `backgroundSecond` fill, 12pt corners, search icon + editable text, filters components by name)
5. **Component cards** (`ComponentCard` — text-only: title in `subtitle1M` + description in `subhead2R`, chevron arrow right, `backgroundSecond` fill, 16pt corners, spring tap animation)

The nav bar reappears on push to preview screens.

### Interactive Component Previews

Each component preview page has two zones:

1. **Preview container** — rounded rect (16pt corners, `backgroundSecond` fill) showing the live component centered. Background updates with brand/theme selection.
2. **Controls panel** — segmented controls to interactively change component properties:
   - **State**: Component-specific states (e.g., Default / Active / Avatar)
   - **Size**: Available size variants
   - **Theme**: System / Light / Dark (overrides `userInterfaceStyle` on preview container)
   - **Brand**: Frisbee / TDM / Sover / KCHAT / Sense New (switches `ChipsColorScheme` via `DSBrand`)

The component is destroyed and re-created on each control change (simplest approach, avoids state management complexity).

### Status badges build phase

A pre-build "Sync Design System Counts" script phase (`scripts/sync-design-system-counts.sh`) automatically:
1. Runs `git pull --ff-only` on both the icons-library and ios-components repos (cached — only pulls if >10 min since last sync, skips silently if offline)
2. Reads `metadata.json`, `colors.json`, and `specs/index.json` from the local repos
3. Gets last commit dates for icons, colors, and components via `git log`
4. Writes `GalleryApp/Resources/design-system-counts.json` with counts and ISO 8601 timestamps

The app reads this bundled JSON at launch — no network calls at runtime.

```bash
# Open in Xcode
open GalleryApp/GalleryApp.xcodeproj

# Or build from command line
cd GalleryApp
xcodebuild -project GalleryApp.xcodeproj -scheme GalleryApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## For LLMs

When working on this repo:

- **ICONS AND COLORS**: Read and follow the "Design System Rules (MANDATORY)" section above. Use ONLY icons-library icons and color tokens. No SF Symbols. No hardcoded colors. No system colors. Call `list_icons`, `get_icon`, and `list_colors` MCP tools to discover available assets before building any UI.
- **TYPOGRAPHY**: Use ONLY `DSTypography` styles (Roboto). No `.systemFont()`, no SF Pro, no custom sizes. In Components package, use the `robotoFont(size:weight:)` helper. Call `DSTypography.style.font` for UIFont or `.apply(to:)` for full line height + letter spacing.
- **DESIGN PRINCIPLES**: Follow spacing, corner radii, typography, and visual patterns defined above. These are extracted from approved reference designs and are binding.
- **COMPONENT THEMING**: New components MUST use injectable color schemes (like `ChipsColorScheme`). No hardcoded colors in `Sources/Components/`. The GalleryApp preview uses `DSBrand` to inject brand-specific palettes. Close icons and other assets are injected via parameters — never use SF Symbols in component code.
- **Source files**: Only edit files in `Sources/Components/` - never edit GalleryApp build artifacts
- **Specs sync**: JSON specs in `specs/` are fetched live by MCP server via raw.githubusercontent.com
- **Testing**: Always test components in GalleryApp before committing
- **Naming**: Use PascalCase for component names (e.g., `ChipsView`, `ContextMenuView`)
- **iOS version**: Minimum deployment target is iOS 14
- **No storyboards**: All UI is programmatic UIKit

## Team Sync Awareness

When team members push changes to the icons library or this components library, other developers can check for updates via the **MCP check_updates tool**, which gives detailed changelogs on demand.

The Claude Code **status line** (`scripts/statusline-command.sh`) shows a context window progress bar only. Copy to `~/.claude/statusline-command.sh` and configure in `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  }
}
```

### Team setup
1. Clone both repos side by side
2. Run `npm install` in both `mcp-server/` directories
3. Copy `scripts/statusline-command.sh` to `~/.claude/statusline-command.sh`
4. Add MCP server entries to `~/.claude.json` (adjust paths to your local clones)
5. Configure status line in `~/.claude/settings.json` (see above)

## Related repos

- **icons-library**: https://github.com/evgenyshkuratov-rgb/icons-library - Icon assets (276 icons, 157 color tokens), Figma sync every 6h via GitHub Actions. Has its own MCP server (`mcp-server/`) with tools: `list_icons`, `list_colors`, `get_icon`, `check_updates`. Both MCP servers are registered globally in `~/.claude.json`. The GalleryApp build phase reads from this repo's local clone to populate status badge counts.
