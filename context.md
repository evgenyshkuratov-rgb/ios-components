# iOS Components Library

## What is this?

UIKit component library for rapid prototyping with LLM-friendly JSON specs. Components are polished and near-production quality, designed for developers to reference and adapt. An MCP server provides Claude Code with direct access to component specifications.

**GitHub repo:** https://github.com/evgenyshkuratov-rgb/ios-components

## Design System Rules (MANDATORY)

> **STRICT RULE: Every component and the GalleryApp interface MUST use ONLY icons and colors from the connected icons-library. No SF Symbols, no hardcoded hex colors, no system colors. Zero exceptions.**

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

#### Typography (SF Pro)
- **Large titles**: Bold, 28–34pt
- **Section headers**: Bold, 22pt
- **Body text**: Regular, 16pt
- **Secondary/subtitle text**: Regular, 14pt, use Basic Colors/50%
- **Button text**: Semibold, 16pt, White/100% on colored backgrounds
- **Small metadata**: Regular, 12pt, use Basic Colors/30%

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
│       ├── ComponentListVC.swift # Card-based catalog (scroll+stack, hidden nav bar)
│       ├── DesignSystem/
│       │   ├── DSColors.swift    # Dynamic light/dark color tokens (from icons-library)
│       │   ├── DSTypography.swift # SF Pro font presets (largeTitle…caption)
│       │   ├── DSSpacing.swift   # Spacing & corner radius tokens
│       │   ├── DSIcon.swift      # Runtime SVG→UIImage renderer
│       │   └── SVGPathParser.swift # Bezier path parser for SVG <path> elements
│       ├── Previews/
│       │   └── ChipsViewPreviewVC.swift  # Per-section stacks (8pt inner, 24pt between)
│       ├── Resources/
│       │   ├── Info.plist
│       │   ├── Icons/            # Bundled SVG icon files from icons-library
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
        └── 2026-02-09-team-sync-awareness-implementation.md
```

## Available components

| Component | Description | States |
|-----------|-------------|--------|
| ChipsView | Filter chip with icon, text, and avatar variants | Default, Active, Avatar |

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

let chip = ChipsView()
chip.configure(text: "Filter option", icon: IconsLibrary.icon(named: "user-2"), state: .active, size: .medium)
chip.onTap = { print("Tapped") }
```

## GalleryApp

Xcode project for browsing and testing components. Main screen has a **hidden nav bar** with content rendered directly in a scroll view: a compact inline status line (e.g., `1 Component (3d) · 276 Icons (1h) · 157 Colors (1h)`), a large "Components" title, and **card-based navigation** (`ComponentCardView` — rounded background, title, description, arrow icon, tap animation). The nav bar reappears on push to preview screens. ChipsView preview uses **per-section stacks** (8pt spacing within sections, 24pt between sections).

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
- **DESIGN PRINCIPLES**: Follow spacing, corner radii, typography, and visual patterns defined above. These are extracted from approved reference designs and are binding.
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
