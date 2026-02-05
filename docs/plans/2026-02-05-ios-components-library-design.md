# iOS Components Library Design

## Overview

A UIKit component library for rapid prototyping with LLM-friendly specs. Components are polished and near-production quality, designed for developers to reference and adapt.

## Goals

- **Rapid prototyping**: Quickly assemble screens and features
- **Polished components**: Near-production quality that developers can reference
- **LLM-friendly**: JSON specs enable Claude to understand components with minimal tokens
- **Team collaboration**: GitHub as source of truth, automatic sync via MCP

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GITHUB                                  │
│                                                                 │
│       ┌─────────────────────────────────────┐                  │
│       │        ios-components               │                  │
│       │                                     │                  │
│       │  ├── Sources/Components/            │                  │
│       │  │   ├── ContextMenuView.swift      │                  │
│       │  │   ├── ReactionBarView.swift      │                  │
│       │  │   └── ...                        │                  │
│       │  ├── GalleryApp/                    │                  │
│       │  ├── specs/                         │                  │
│       │  │   ├── index.json                 │                  │
│       │  │   └── components/*.json          │                  │
│       │  └── mcp-server/                    │                  │
│       └─────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
                            ↓
                   fetches specs via
                   raw.githubusercontent
                            ↓
              ┌─────────────────────────┐
              │   ios-components-mcp    │
              │   (npm package)         │
              │                         │
              │   Tools:                │
              │   • list_components     │
              │   • get_component       │
              │   • search_components   │
              └─────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    CLAUDE CODE SESSION                          │
│         (any team member, any computer)                         │
│                                                                 │
│  "Build a chat screen with context menu"                        │
│         → Claude queries MCP                                    │
│         → Gets component specs                                  │
│         → Generates correct UIKit code                          │
└─────────────────────────────────────────────────────────────────┘
```

## Repository Structure

```
ios-components/
├── README.md                     # Setup instructions for team
├── Package.swift                 # Swift Package definition
│
├── Sources/
│   └── Components/
│       ├── ContextMenuView.swift
│       ├── ReactionBarView.swift
│       ├── ContextMenuAnimator.swift
│       ├── ContextMenuModels.swift
│       ├── GradientView.swift
│       ├── Constants.swift
│       ├── TDMColors.swift
│       └── Fonts+App.swift
│
├── GalleryApp/
│   ├── GalleryApp.xcodeproj
│   └── GalleryApp/
│       ├── AppDelegate.swift
│       ├── ComponentListVC.swift
│       ├── Previews/
│       │   ├── ContextMenuPreviewVC.swift
│       │   ├── ReactionBarPreviewVC.swift
│       │   └── ...
│       └── Resources/
│
├── specs/
│   ├── index.json
│   └── components/
│       ├── ContextMenuView.json
│       ├── ReactionBarView.json
│       └── ...
│
└── mcp-server/
    ├── package.json
    ├── index.js
    └── README.md
```

## JSON Spec Format

### specs/index.json

For `list_components` tool - lightweight index of all components:

```json
{
  "version": "1.0.0",
  "components": [
    {
      "name": "ContextMenuView",
      "description": "Full-screen overlay with reactions, quick actions, and list actions for messages"
    },
    {
      "name": "ReactionBarView",
      "description": "Horizontal emoji reaction picker with add button"
    },
    {
      "name": "GradientView",
      "description": "UIView subclass that renders a two-color gradient"
    }
  ]
}
```

### specs/components/*.json

For `get_component` tool - full component specification:

```json
{
  "name": "ContextMenuView",
  "description": "Full-screen overlay with blurred background, emoji reactions, message snapshot, and action buttons",
  "import": "import Components",
  "properties": [
    {
      "name": "quickActions",
      "type": "[ContextMenuAction]",
      "description": "Top row actions (Reply, Copy, Edit)"
    },
    {
      "name": "primaryListActions",
      "type": "[ContextMenuAction]",
      "description": "Default list actions shown initially"
    },
    {
      "name": "secondaryListActions",
      "type": "[ContextMenuAction]",
      "description": "Actions shown after tapping 'More...'"
    },
    {
      "name": "deleteAction",
      "type": "ContextMenuAction?",
      "description": "Destructive delete action at bottom"
    }
  ],
  "usage": "let menu = ContextMenuView()\nmenu.configure(\n    quickActions: [replyAction, copyAction],\n    primaryListActions: [pinAction, forwardAction],\n    secondaryListActions: [selectAction, reportAction],\n    deleteAction: deleteAction,\n    dismissHandler: { print(\"dismissed\") }\n)\nmenu.show(from: messageView, in: view, isOutgoing: true)",
  "tags": ["menu", "context", "actions", "overlay", "message"]
}
```

## MCP Server

### mcp-server/package.json

```json
{
  "name": "@yourteam/ios-components-mcp",
  "version": "1.0.0",
  "description": "MCP server for iOS components library",
  "bin": {
    "ios-components-mcp": "./index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  }
}
```

### mcp-server/index.js

```javascript
#!/usr/bin/env node

const { McpServer } = require("@modelcontextprotocol/sdk/server/mcp.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");

const GITHUB_BASE = "https://raw.githubusercontent.com/yourteam/ios-components/main/specs";

const server = new McpServer({
  name: "ios-components",
  version: "1.0.0"
});

// Tool: list_components
// Returns all available components with brief descriptions
server.tool(
  "list_components",
  "List all available iOS components",
  {},
  async () => {
    const res = await fetch(`${GITHUB_BASE}/index.json`);
    const data = await res.json();
    return {
      content: [{
        type: "text",
        text: JSON.stringify(data.components, null, 2)
      }]
    };
  }
);

// Tool: get_component
// Returns full specification for a single component
server.tool(
  "get_component",
  "Get full specification for a component including properties and usage",
  {
    name: {
      type: "string",
      description: "Component name (e.g., ContextMenuView)",
      required: true
    }
  },
  async ({ name }) => {
    const res = await fetch(`${GITHUB_BASE}/components/${name}.json`);
    if (!res.ok) {
      return {
        content: [{
          type: "text",
          text: `Component "${name}" not found`
        }]
      };
    }
    const spec = await res.json();
    return {
      content: [{
        type: "text",
        text: JSON.stringify(spec, null, 2)
      }]
    };
  }
);

// Tool: search_components
// Search components by name, description, or tags
server.tool(
  "search_components",
  "Search for components by keyword",
  {
    query: {
      type: "string",
      description: "Search query (matches name, description, or tags)",
      required: true
    }
  },
  async ({ query }) => {
    const res = await fetch(`${GITHUB_BASE}/index.json`);
    const data = await res.json();
    const q = query.toLowerCase();
    const matches = data.components.filter(c =>
      c.name.toLowerCase().includes(q) ||
      c.description.toLowerCase().includes(q) ||
      (c.tags && c.tags.some(t => t.includes(q)))
    );
    return {
      content: [{
        type: "text",
        text: JSON.stringify(matches, null, 2)
      }]
    };
  }
);

// Start server
const transport = new StdioServerTransport();
server.connect(transport);
```

## Gallery App

Simple UIKit catalog to browse and test components.

### ComponentListViewController.swift

```swift
import UIKit
import Components

final class ComponentListViewController: UITableViewController {

    private let components = [
        ("ContextMenuView", "Full-screen context menu overlay"),
        ("ReactionBarView", "Emoji reaction picker"),
        ("GradientView", "Two-color gradient view")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Components"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        components.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let (name, description) = components[indexPath.row]
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = description
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc: UIViewController
        switch indexPath.row {
        case 0: vc = ContextMenuPreviewVC()
        case 1: vc = ReactionBarPreviewVC()
        case 2: vc = GradientViewPreviewVC()
        default: return
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
```

## Team Workflow

### Adding a new component

```
1. Create component
   └── Sources/Components/ButtonView.swift

2. Generate spec (Claude helps)
   └── specs/components/ButtonView.json

3. Update index
   └── specs/index.json (add entry)

4. Add preview
   └── GalleryApp/Previews/ButtonPreviewVC.swift

5. Push to GitHub
   └── git add . && git commit && git push

6. Done - all team members instantly have access
```

### Using components in a new project

```
Team member: "Build a settings screen with buttons and a context menu"

Claude:
  1. Calls list_components → sees available components
  2. Calls get_component("ButtonView") → gets spec
  3. Calls get_component("ContextMenuView") → gets spec
  4. Generates correct UIKit code using specs
```

### First-time setup for new team member

```bash
# One-time setup (30 seconds)
npm install -g @yourteam/ios-components-mcp

# Add to Claude Code config (~/.claude.json)
{
  "mcpServers": {
    "ios-components": {
      "command": "ios-components-mcp"
    }
  }
}

# Done - Claude now knows your components
```

## Implementation Steps

### Phase 1: Repository Setup
- Create `ios-components` GitHub repo
- Initialize Swift Package structure
- Set up GalleryApp Xcode project
- Create specs folder structure

### Phase 2: Migrate Existing Components
- Move `ContextMenuView`, `ReactionBarView`, `ContextMenuAnimator`, `ContextMenuModels` from context menu project
- Move supporting files: `TDMColors`, `Constants`, `Fonts+App`, `GradientView`
- Create JSON specs for each component
- Build preview screens in GalleryApp

### Phase 3: MCP Server
- Build MCP server with three tools
- Test locally with Claude Code
- Publish to npm (private or public)

### Phase 4: Team Onboarding
- Write README with setup instructions
- Share with team members
- Iterate based on feedback

## Summary

| Aspect | Decision |
|--------|----------|
| **Goal** | Polished prototyping components (UIKit) |
| **Repo** | Single repo: components + gallery + MCP + specs |
| **Organization** | Flat list with search |
| **Specs** | JSON, generated when building each component |
| **Distribution** | Swift Package (for code), npm (for MCP) |
| **Sync** | GitHub is source of truth, MCP fetches live |
| **Team setup** | One-time npm install + config |
