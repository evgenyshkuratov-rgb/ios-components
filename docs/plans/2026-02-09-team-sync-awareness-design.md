# Team Sync Awareness System

**Date:** 2026-02-09
**Goal:** When a team member pushes changes to the Icons Library or iOS Components Library, other team members see those updates immediately when they open Claude Code.

## Architecture

Two layers:

1. **Status line** (always visible) — shell script using `git fetch` to show change counts
2. **MCP tools** (on-demand) — `check_updates` tools on both MCP servers for detailed changelogs

```
┌─────────────────────────────────────────────────────────┐
│  Status Line (shell script, always visible)             │
│  [████░░░░░░] 40% | Icons: +3 new (2h) | Comps: ✓      │
│                                                         │
│  Mechanism: git fetch (cached, max every 5 min)         │
│  Compares: main..origin/main file diffs                 │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  MCP Tools (interactive, on-demand)                     │
│  icons-library server:  check_updates → detailed diff   │
│  ios-components server: check_updates → changelog       │
│                                                         │
│  Use case: "What icons changed?" → full details         │
└─────────────────────────────────────────────────────────┘
```

## Component 1: Status Line Script

**File:** `~/.claude/statusline-command.sh`

Extends the existing context window progress bar with library status.

### Output format

```
[████░░░░░░] 40% | Icons: +3 new, 1 mod (2h) | Comps: ✓
```

- `✓` = up to date with remote
- `+N new, M mod (Xh)` = behind remote, with time since latest remote commit
- `?` = repo not found or fetch failed

### Fetch caching

To avoid slowing down status line rendering:
- Store last fetch timestamp in `/tmp/.claude-fetch-{repo}`
- Only run `git fetch` if last fetch was >5 minutes ago
- Read cached git diff results otherwise

### Logic

```
for each repo (icons-library, ios-components):
  1. Check if repo directory exists
  2. If cache file is stale (>5 min) or missing:
     - Run: git fetch origin main --quiet
     - Update cache timestamp
  3. Count divergence:
     - git rev-list --count main..origin/main
     - If 0: show "✓"
     - If >0:
       - git diff --name-only --diff-filter=A main..origin/main | count (new files)
       - git diff --name-only --diff-filter=M main..origin/main | count (modified files)
       - git log -1 --format=%cr origin/main (time ago)
  4. For icons: filter to icons/*.svg and colors.json
  5. For components: filter to Sources/ and specs/
```

### Repo paths

Configurable via environment variables with defaults:
- `ICONS_REPO_PATH` → default: `../Icons library` (relative to ios-land-component)
- `COMPONENTS_REPO_PATH` → default: current working directory

## Component 2: Icons Library MCP Server

**Location:** `/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server/`

New MCP server for the Icons Library. Uses the same pattern as the existing ios-components MCP server.

### Tools

#### `list_icons`
- Lists all icons from metadata.json
- Returns: name, category, tags for each icon
- Source: local metadata.json file (not GitHub API)

#### `list_colors`
- Lists all color tokens from colors.json
- Returns: name, brand values, light/dark modes
- Source: local colors.json file

#### `check_updates`
- Runs `git fetch` then compares local main vs origin/main
- Input: optional `since` parameter (commit SHA or date)
- Returns:
  - Number of commits behind
  - List of new/modified/deleted icons (SVG files)
  - List of new/modified colors
  - Commit messages with authors and timestamps
  - Last Figma sync timestamp from colors.json

#### `get_icon`
- Get full metadata for a specific icon
- Input: icon name (kebab-case)
- Returns: category, tags, figmaNodeId

### Implementation

```javascript
// Uses child_process.execSync for git commands
// Reads metadata.json and colors.json from local filesystem
// No external API calls needed
```

## Component 3: iOS Components MCP Enhancement

**File:** `/Users/evgeny.shkuratov/Clode code projects/ios-land-component/mcp-server/index.js`

Add one new tool to the existing server.

### New tool: `check_updates`
- Runs `git fetch` then compares local main vs origin/main
- Returns:
  - Number of commits behind
  - List of new/modified components (Sources/ and specs/)
  - Commit messages with authors and timestamps

### Implementation

Same git-based approach as the icons server. Uses local repo path derived from `import.meta.url`.

## Component 4: Registration

Both MCP servers registered globally in `~/.claude.json`:

```json
{
  "mcpServers": {
    "playwright": { ... },
    "figma": { ... },
    "icons-library": {
      "command": "node",
      "args": ["/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server/index.js"]
    },
    "ios-components": {
      "command": "node",
      "args": ["/Users/evgeny.shkuratov/Clode code projects/ios-land-component/mcp-server/index.js"]
    }
  }
}
```

Using absolute paths with `node` command so no global npm install is needed.

## Implementation Plan

### Step 1: Create Icons Library MCP server
- Create `mcp-server/` directory in Icons Library
- Implement package.json and index.js with all 4 tools
- Install dependencies
- Test locally

### Step 2: Add `check_updates` to iOS Components MCP server
- Add the new tool to existing index.js
- Test locally

### Step 3: Update status line script
- Extend `~/.claude/statusline-command.sh`
- Add git fetch caching and change count logic
- Test output format

### Step 4: Register MCP servers
- Add both servers to `~/.claude.json`
- Verify they appear in Claude Code

### Step 5: Test end-to-end
- Push a test change to icons library
- Verify status line updates
- Verify MCP check_updates returns correct data

## Team Setup

For other team members to get the same experience:
1. Clone both repos side by side
2. Copy the updated `statusline-command.sh` (or store it in a shared dotfiles repo)
3. Add MCP server entries to their `~/.claude.json` (adjust paths)
4. Run `npm install` in both `mcp-server/` directories
