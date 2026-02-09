# Team Sync Awareness Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Surface upstream changes in Icons Library and iOS Components Library via Claude Code status line and MCP tools, so team members see updates when they open a session.

**Architecture:** Two layers — a shell-based status line script using cached `git fetch` for at-a-glance awareness, plus `check_updates` MCP tools on both servers for interactive detailed changelogs. Both MCP servers read local files and git state, no external APIs needed.

**Tech Stack:** Node.js (ES modules), @modelcontextprotocol/sdk, Bash, git CLI, jq

---

### Task 1: Create Icons Library MCP Server — package.json

**Files:**
- Create: `/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server/package.json`

**Step 1: Create the mcp-server directory**

Run: `mkdir -p "/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server"`

**Step 2: Write package.json**

Create `/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server/package.json`:

```json
{
  "name": "@evgenyshkuratov-rgb/icons-library-mcp",
  "version": "1.0.0",
  "description": "MCP server for Icons & Colors library - provides icon/color metadata and change tracking to Claude",
  "type": "module",
  "bin": {
    "icons-library-mcp": "./index.js"
  },
  "files": [
    "index.js"
  ],
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  },
  "keywords": ["mcp", "icons", "colors", "figma", "claude"],
  "author": "evgenyshkuratov-rgb",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/evgenyshkuratov-rgb/icons-library.git"
  }
}
```

**Step 3: Install dependencies**

Run: `cd "/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server" && npm install`
Expected: node_modules created with @modelcontextprotocol/sdk

**Step 4: Commit**

```bash
cd "/Users/evgeny.shkuratov/Clode code projects/Icons library"
git add mcp-server/package.json mcp-server/package-lock.json
git commit -m "feat: add MCP server package scaffold"
```

---

### Task 2: Create Icons Library MCP Server — index.js with all tools

**Files:**
- Create: `/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server/index.js`

**Step 1: Write index.js**

Create `/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server/index.js`:

```javascript
#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { readFileSync } from "fs";
import { execSync } from "child_process";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "..");

function readJSON(filename) {
  return JSON.parse(readFileSync(resolve(REPO_ROOT, filename), "utf-8"));
}

function git(cmd) {
  return execSync(cmd, { cwd: REPO_ROOT, encoding: "utf-8", timeout: 15000 }).trim();
}

const server = new McpServer({
  name: "icons-library",
  version: "1.0.0"
});

// Tool: list_icons
server.tool(
  "list_icons",
  "List all icons in the library with their categories and tags",
  {},
  async () => {
    try {
      const meta = readJSON("metadata.json");
      const summary = meta.icons.map(i => ({
        name: i.name,
        category: i.category,
        tags: i.tags
      }));
      return {
        content: [{
          type: "text",
          text: `${summary.length} icons in ${meta.categories.length} categories:\n\n` +
            JSON.stringify(summary, null, 2)
        }]
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error reading icons: ${error.message}` }]
      };
    }
  }
);

// Tool: get_icon
server.tool(
  "get_icon",
  "Get full metadata for a specific icon by name (kebab-case)",
  {
    name: {
      type: "string",
      description: "Icon name in kebab-case (e.g., 'arrow-left', 'cache-memory')"
    }
  },
  async ({ name }) => {
    try {
      const meta = readJSON("metadata.json");
      const icon = meta.icons.find(i => i.name === name);
      if (!icon) {
        return {
          content: [{
            type: "text",
            text: `Icon "${name}" not found. Use list_icons to see all available icons.`
          }]
        };
      }
      return {
        content: [{ type: "text", text: JSON.stringify(icon, null, 2) }]
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error: ${error.message}` }]
      };
    }
  }
);

// Tool: list_colors
server.tool(
  "list_colors",
  "List all color tokens with their brand/mode values",
  {},
  async () => {
    try {
      const colors = readJSON("colors.json");
      const summary = colors.colors.map(c => ({
        name: c.name,
        kebabName: c.kebabName,
        values: c.values
      }));
      return {
        content: [{
          type: "text",
          text: `${summary.length} color tokens across ${colors.brands.length} brands (${colors.modes.join(", ")}):\n\n` +
            JSON.stringify(summary, null, 2)
        }]
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error reading colors: ${error.message}` }]
      };
    }
  }
);

// Tool: check_updates
server.tool(
  "check_updates",
  "Check for upstream changes in the icons library — shows new/modified icons, colors, and commit messages since your local branch",
  {},
  async () => {
    try {
      // Fetch latest from remote
      try {
        git("git fetch origin main --quiet");
      } catch {
        return {
          content: [{
            type: "text",
            text: "Could not fetch from remote. Check network connection."
          }]
        };
      }

      // Count commits behind
      let commitsBehind;
      try {
        commitsBehind = parseInt(git("git rev-list --count main..origin/main"), 10);
      } catch {
        commitsBehind = 0;
      }

      if (commitsBehind === 0) {
        return {
          content: [{
            type: "text",
            text: "Up to date — no new changes on remote."
          }]
        };
      }

      // Get changed files
      const newFiles = git("git diff --name-only --diff-filter=A main..origin/main").split("\n").filter(Boolean);
      const modifiedFiles = git("git diff --name-only --diff-filter=M main..origin/main").split("\n").filter(Boolean);
      const deletedFiles = git("git diff --name-only --diff-filter=D main..origin/main").split("\n").filter(Boolean);

      // Filter to relevant files
      const newIcons = newFiles.filter(f => f.startsWith("icons/") && f.endsWith(".svg"));
      const modIcons = modifiedFiles.filter(f => f.startsWith("icons/") && f.endsWith(".svg"));
      const delIcons = deletedFiles.filter(f => f.startsWith("icons/") && f.endsWith(".svg"));
      const colorsChanged = modifiedFiles.includes("colors.json") || newFiles.includes("colors.json");

      // Get commit log
      const log = git('git log --oneline --format="%h %s (%an, %cr)" main..origin/main');

      // Get last Figma sync time
      let lastSync = "unknown";
      try {
        const colors = readJSON("colors.json");
        if (colors.lastSync) lastSync = colors.lastSync;
      } catch { /* ignore */ }

      const lines = [
        `## Icons Library: ${commitsBehind} commit(s) behind remote\n`,
      ];

      if (newIcons.length > 0) {
        lines.push(`**New icons (${newIcons.length}):** ${newIcons.map(f => f.replace("icons/", "").replace(".svg", "")).join(", ")}`);
      }
      if (modIcons.length > 0) {
        lines.push(`**Modified icons (${modIcons.length}):** ${modIcons.map(f => f.replace("icons/", "").replace(".svg", "")).join(", ")}`);
      }
      if (delIcons.length > 0) {
        lines.push(`**Deleted icons (${delIcons.length}):** ${delIcons.map(f => f.replace("icons/", "").replace(".svg", "")).join(", ")}`);
      }
      if (colorsChanged) {
        lines.push("**Colors:** colors.json was modified");
      }
      if (newIcons.length === 0 && modIcons.length === 0 && delIcons.length === 0 && !colorsChanged) {
        const otherFiles = [...newFiles, ...modifiedFiles, ...deletedFiles];
        lines.push(`**Changed files:** ${otherFiles.join(", ")}`);
      }

      lines.push(`\n**Commits:**\n${log}`);
      lines.push(`\n**Last Figma sync:** ${lastSync}`);

      return {
        content: [{ type: "text", text: lines.join("\n") }]
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error checking updates: ${error.message}` }]
      };
    }
  }
);

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);
```

**Step 2: Test the server starts**

Run: `cd "/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server" && echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | node index.js 2>/dev/null | head -1`

Expected: A JSON response containing `"name":"icons-library"` (server initializes and responds to the init handshake).

**Step 3: Commit**

```bash
cd "/Users/evgeny.shkuratov/Clode code projects/Icons library"
git add mcp-server/index.js
git commit -m "feat: add MCP server with list_icons, list_colors, get_icon, and check_updates tools"
```

---

### Task 3: Add check_updates tool to iOS Components MCP server

**Files:**
- Modify: `/Users/evgeny.shkuratov/Clode code projects/ios-land-component/mcp-server/index.js`

**Step 1: Add imports**

Add after line 2 (`import { StdioServerTransport }...`):

```javascript
import { execSync } from "child_process";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "..");

function git(cmd) {
  return execSync(cmd, { cwd: REPO_ROOT, encoding: "utf-8", timeout: 15000 }).trim();
}
```

**Step 2: Add check_updates tool**

Add before the `// Start server` comment (before line 147):

```javascript
// Tool: check_updates
// Compare local vs remote for new/modified components
server.tool(
  "check_updates",
  "Check for upstream changes in the iOS components library — shows new/modified components and commit messages",
  {},
  async () => {
    try {
      try {
        git("git fetch origin main --quiet");
      } catch {
        return {
          content: [{
            type: "text",
            text: "Could not fetch from remote. Check network connection."
          }]
        };
      }

      let commitsBehind;
      try {
        commitsBehind = parseInt(git("git rev-list --count main..origin/main"), 10);
      } catch {
        commitsBehind = 0;
      }

      if (commitsBehind === 0) {
        return {
          content: [{
            type: "text",
            text: "Up to date — no new changes on remote."
          }]
        };
      }

      const newFiles = git("git diff --name-only --diff-filter=A main..origin/main").split("\n").filter(Boolean);
      const modifiedFiles = git("git diff --name-only --diff-filter=M main..origin/main").split("\n").filter(Boolean);
      const deletedFiles = git("git diff --name-only --diff-filter=D main..origin/main").split("\n").filter(Boolean);

      const newComps = newFiles.filter(f => f.startsWith("Sources/") || f.startsWith("specs/"));
      const modComps = modifiedFiles.filter(f => f.startsWith("Sources/") || f.startsWith("specs/"));
      const delComps = deletedFiles.filter(f => f.startsWith("Sources/") || f.startsWith("specs/"));

      const log = git('git log --oneline --format="%h %s (%an, %cr)" main..origin/main');

      const lines = [
        `## iOS Components: ${commitsBehind} commit(s) behind remote\n`,
      ];

      if (newComps.length > 0) {
        lines.push(`**New files (${newComps.length}):** ${newComps.join(", ")}`);
      }
      if (modComps.length > 0) {
        lines.push(`**Modified files (${modComps.length}):** ${modComps.join(", ")}`);
      }
      if (delComps.length > 0) {
        lines.push(`**Deleted files (${delComps.length}):** ${delComps.join(", ")}`);
      }
      if (newComps.length === 0 && modComps.length === 0 && delComps.length === 0) {
        const otherFiles = [...newFiles, ...modifiedFiles, ...deletedFiles];
        lines.push(`**Changed files:** ${otherFiles.join(", ")}`);
      }

      lines.push(`\n**Commits:**\n${log}`);

      return {
        content: [{ type: "text", text: lines.join("\n") }]
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error checking updates: ${error.message}` }]
      };
    }
  }
);
```

**Step 3: Test the server starts**

Run: `cd "/Users/evgeny.shkuratov/Clode code projects/ios-land-component/mcp-server" && echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | node index.js 2>/dev/null | head -1`

Expected: JSON response with `"name":"ios-components"`

**Step 4: Commit**

```bash
cd "/Users/evgeny.shkuratov/Clode code projects/ios-land-component"
git add mcp-server/index.js
git commit -m "feat: add check_updates tool to MCP server for team sync awareness"
```

---

### Task 4: Update status line script

**Files:**
- Modify: `/Users/evgeny.shkuratov/.claude/statusline-command.sh`

**Step 1: Replace the status line script**

Replace the full content of `~/.claude/statusline-command.sh` with:

```bash
#!/bin/bash

# Configurable repo paths (override via env vars)
ICONS_REPO="${ICONS_REPO_PATH:-$HOME/Clode code projects/Icons library}"
COMPONENTS_REPO="${COMPONENTS_REPO_PATH:-$HOME/Clode code projects/ios-land-component}"
CACHE_DIR="/tmp/.claude-sync-cache"
CACHE_TTL=300  # 5 minutes in seconds

mkdir -p "$CACHE_DIR"

# --- Context window bar (existing functionality) ---
input=$(cat)
status_parts=()

usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
  current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
  size=$(echo "$input" | jq '.context_window.context_window_size')
  pct=$((current * 100 / size))

  filled=$((pct / 10))
  empty=$((10 - filled))

  bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty; i++)); do bar="${bar}░"; done

  status_parts+=("[${bar}] ${pct}%")
fi

# --- Repo sync check function ---
check_repo() {
  local repo_path="$1"
  local label="$2"
  local filter_prefix="$3"  # e.g., "icons/" or "Sources/\|specs/"
  local cache_file="$CACHE_DIR/${label}"

  # Check repo exists
  if [ ! -d "$repo_path/.git" ]; then
    echo "${label}: ?"
    return
  fi

  # Check cache freshness
  local now
  now=$(date +%s)
  local needs_fetch=1

  if [ -f "${cache_file}.ts" ]; then
    local last_fetch
    last_fetch=$(cat "${cache_file}.ts")
    if [ $((now - last_fetch)) -lt $CACHE_TTL ]; then
      needs_fetch=0
    fi
  fi

  # Fetch if needed (background, don't block)
  if [ $needs_fetch -eq 1 ]; then
    git -C "$repo_path" fetch origin main --quiet 2>/dev/null &
    FETCH_PID=$!
    # Wait max 3 seconds for fetch
    local waited=0
    while kill -0 $FETCH_PID 2>/dev/null && [ $waited -lt 3 ]; do
      sleep 0.5
      waited=$((waited + 1))
    done
    kill $FETCH_PID 2>/dev/null
    wait $FETCH_PID 2>/dev/null
    echo "$now" > "${cache_file}.ts"
  fi

  # Count divergence
  local behind
  behind=$(git -C "$repo_path" rev-list --count main..origin/main 2>/dev/null || echo "0")

  if [ "$behind" = "0" ]; then
    echo "${label}: ✓"
    return
  fi

  # Count new and modified files in the relevant prefix
  local new_count=0
  local mod_count=0

  if [ -n "$filter_prefix" ]; then
    new_count=$(git -C "$repo_path" diff --name-only --diff-filter=A main..origin/main 2>/dev/null | grep -c "$filter_prefix" || echo "0")
    mod_count=$(git -C "$repo_path" diff --name-only --diff-filter=M main..origin/main 2>/dev/null | grep -c "$filter_prefix" || echo "0")
  else
    new_count=$(git -C "$repo_path" diff --name-only --diff-filter=A main..origin/main 2>/dev/null | wc -l | tr -d ' ')
    mod_count=$(git -C "$repo_path" diff --name-only --diff-filter=M main..origin/main 2>/dev/null | wc -l | tr -d ' ')
  fi

  # Time since last remote commit
  local ago
  ago=$(git -C "$repo_path" log -1 --format=%cr origin/main 2>/dev/null || echo "?")
  # Shorten: "2 hours ago" → "2h", "3 days ago" → "3d"
  ago=$(echo "$ago" | sed 's/ seconds\? ago/s/;s/ minutes\? ago/m/;s/ hours\? ago/h/;s/ days\? ago/d/;s/ weeks\? ago/w/')

  local parts=()
  if [ "$new_count" -gt 0 ]; then parts+=("+${new_count} new"); fi
  if [ "$mod_count" -gt 0 ]; then parts+=("${mod_count} mod"); fi

  if [ ${#parts[@]} -eq 0 ]; then
    echo "${label}: ${behind}↓ (${ago})"
  else
    local detail
    detail=$(IFS=', '; echo "${parts[*]}")
    echo "${label}: ${detail} (${ago})"
  fi
}

# --- Check both repos ---
icons_status=$(check_repo "$ICONS_REPO" "Icons" "icons/\|colors.json")
comps_status=$(check_repo "$COMPONENTS_REPO" "Comps" "Sources/\|specs/")

status_parts+=("$icons_status")
status_parts+=("$comps_status")

# --- Output ---
IFS=' | '
printf '%s' "${status_parts[*]}"
```

**Step 2: Test the script**

Run: `echo '{"context_window":{"current_usage":{"input_tokens":1000,"cache_creation_input_tokens":500,"cache_read_input_tokens":200},"context_window_size":200000}}' | bash ~/.claude/statusline-command.sh`

Expected: Something like `[█░░░░░░░░░] 0% | Icons: ✓ | Comps: ✓` (both repos are up to date with remote).

**Step 3: Commit (store a copy in the components repo for team sharing)**

```bash
cp ~/.claude/statusline-command.sh "/Users/evgeny.shkuratov/Clode code projects/ios-land-component/scripts/statusline-command.sh"
cd "/Users/evgeny.shkuratov/Clode code projects/ios-land-component"
git add scripts/statusline-command.sh
git commit -m "feat: add team sync status line script showing icons & components update status"
```

---

### Task 5: Register both MCP servers in Claude config

**Files:**
- Modify: `~/.claude.json` (the `mcpServers` object around line 587)

**Step 1: Add MCP server entries**

In `~/.claude.json`, find the `mcpServers` object (around line 587) and add two new entries after the existing `figma` entry:

Current:
```json
"mcpServers": {
    "playwright": { ... },
    "figma": { ... }
}
```

Add:
```json
"icons-library": {
  "type": "stdio",
  "command": "node",
  "args": [
    "/Users/evgeny.shkuratov/Clode code projects/Icons library/mcp-server/index.js"
  ]
},
"ios-components": {
  "type": "stdio",
  "command": "node",
  "args": [
    "/Users/evgeny.shkuratov/Clode code projects/ios-land-component/mcp-server/index.js"
  ]
}
```

**Step 2: Verify by listing MCP servers**

Restart Claude Code (or start a new session). The MCP server list should now show:
- playwright
- figma
- icons-library (with tools: list_icons, get_icon, list_colors, check_updates)
- ios-components (with tools: list_components, get_component, search_components, check_updates)

---

### Task 6: End-to-end verification

**Step 1: Test Icons MCP list_icons tool**

In a new Claude Code session, ask: "List all icons" — Claude should call the `list_icons` tool and return 117 icons.

**Step 2: Test Icons MCP check_updates tool**

Ask: "Check for icons library updates" — Claude should call `check_updates` and report either "Up to date" or list of changes.

**Step 3: Test Components MCP check_updates tool**

Ask: "Check for component library updates" — same behavior.

**Step 4: Verify status line**

The status line at the bottom of Claude Code should now show:
```
[████░░░░░░] 40% | Icons: ✓ | Comps: ✓
```

**Step 5: Simulate a remote change (optional)**

To verify change detection works, create a test commit on the remote:
1. On GitHub, edit any file in the icons-library repo (e.g., add a comment to metadata.json)
2. Wait for the status line cache to expire (5 min) or manually delete `/tmp/.claude-sync-cache/Icons.ts`
3. Status line should update to: `Icons: 1 mod (1m)`
4. MCP check_updates should show the commit details
