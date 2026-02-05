# iOS Components Library

A UIKit component library for rapid prototyping with LLM-friendly specs.

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/evgenyshkuratov-rgb/ios-components.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter repository URL.

### MCP Server Setup

```bash
npm install -g @evgenyshkuratov-rgb/ios-components-mcp
```

Add to `~/.claude.json`:

```json
{
  "mcpServers": {
    "ios-components": {
      "command": "ios-components-mcp"
    }
  }
}
```

## Components

| Component | Description |
|-----------|-------------|
| ChipsView | Filter chips with Default, Active, and Avatar states |

## Usage

```swift
import Components

let chip = ChipsView()
chip.configure(text: "Filter option", state: .default, size: .medium)
```

## Gallery App

Open `GalleryApp/GalleryApp.xcodeproj` to browse and test all components.
