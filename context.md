# iOS Components Library

## What is this?

UIKit component library for rapid prototyping with LLM-friendly JSON specs. Components are polished and near-production quality, designed for developers to reference and adapt. An MCP server provides Claude Code with direct access to component specifications.

**GitHub repo:** https://github.com/evgenyshkuratov-rgb/ios-components

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
│   ├── GalleryApp.xcodeproj/     # Xcode project
│   └── GalleryApp/
│       ├── AppDelegate.swift     # App entry point
│       ├── ComponentListVC.swift # Component catalog list
│       └── Previews/
│           └── ChipsViewPreviewVC.swift
│
├── mcp-server/
│   ├── package.json              # npm package config
│   ├── index.js                  # MCP server with 4 tools
│   └── README.md                 # MCP setup instructions
│
├── scripts/
│   └── statusline-command.sh     # Team-shared Claude Code status line
│
└── docs/
    └── plans/                    # Design documents
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
| `list_components` | Returns all components with brief descriptions |
| `get_component` | Returns full spec for a component by name |
| `search_components` | Search by keyword in name/description/tags |
| `check_updates` | Check for upstream changes — shows new/modified components and commit messages |

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
chip.configure(text: "Filter option", icon: UIImage(systemName: "person.2"), state: .active, size: .medium)
chip.onTap = { print("Tapped") }
```

## GalleryApp

Xcode project for browsing and testing components.

```bash
# Open in Xcode
open GalleryApp/GalleryApp.xcodeproj

# Or build from command line
cd GalleryApp
xcodebuild -project GalleryApp.xcodeproj -scheme GalleryApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## For LLMs

When working on this repo:

- **Source files**: Only edit files in `Sources/Components/` - never edit GalleryApp build artifacts
- **Specs sync**: JSON specs in `specs/` are fetched live by MCP server via raw.githubusercontent.com
- **Testing**: Always test components in GalleryApp before committing
- **Naming**: Use PascalCase for component names (e.g., `ChipsView`, `ContextMenuView`)
- **iOS version**: Minimum deployment target is iOS 14
- **No storyboards**: All UI is programmatic UIKit

## Team Sync Awareness

When team members push changes to the icons library or this components library, other developers see updates automatically via:

1. **Status line** — Claude Code shows `Icons: +3 new (2h) | Comps: ✓` in the bottom bar
2. **MCP check_updates tool** — Claude can give detailed changelogs on demand

The status line script is at `scripts/statusline-command.sh` (copy to `~/.claude/statusline-command.sh`). It uses cached `git fetch` (every 5 min) to compare local vs remote branches.

Both the icons-library and ios-components MCP servers have a `check_updates` tool that fetches from remote and reports new/modified/deleted files with commit messages.

### Team setup
1. Clone both repos side by side
2. Run `npm install` in both `mcp-server/` directories
3. Copy `scripts/statusline-command.sh` to `~/.claude/statusline-command.sh`
4. Add MCP server entries to `~/.claude.json` (adjust paths to your local clones)
5. Configure status line in `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  }
}
```

Repo paths are configurable via `ICONS_REPO_PATH` and `COMPONENTS_REPO_PATH` env vars.

## Related repos

- **icons-library**: https://github.com/evgenyshkuratov-rgb/icons-library - Icon assets with colors, has its own MCP server with `list_icons`, `list_colors`, `get_icon`, `check_updates` tools
