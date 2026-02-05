# iOS Components MCP Server

MCP server that provides iOS UIKit component specifications to Claude Code.

## Installation

```bash
npm install -g @evgenyshkuratov-rgb/ios-components-mcp
```

## Configuration

Add to your Claude Code config (`~/.claude.json`):

```json
{
  "mcpServers": {
    "ios-components": {
      "command": "ios-components-mcp"
    }
  }
}
```

## Available Tools

### list_components

Lists all available iOS components with brief descriptions.

```
> list_components
[
  {
    "name": "ChipsView",
    "description": "Filter chip with Default, Active, and Avatar states in two sizes (32pt, 40pt)"
  }
]
```

### get_component

Gets full specification for a component including properties, usage examples, and tags.

```
> get_component name="ChipsView"
{
  "name": "ChipsView",
  "description": "...",
  "import": "import Components",
  "properties": [...],
  "usage": "...",
  "tags": [...]
}
```

### search_components

Searches components by keyword (matches name, description, or tags).

```
> search_components query="filter"
[
  {
    "name": "ChipsView",
    "description": "Filter chip with Default, Active, and Avatar states..."
  }
]
```

## Development

```bash
cd mcp-server
npm install
node index.js
```

## Publishing

```bash
npm publish --access public
```
