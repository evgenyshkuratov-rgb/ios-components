#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const GITHUB_BASE = "https://raw.githubusercontent.com/evgenyshkuratov-rgb/ios-components/main/specs";

const server = new McpServer({
  name: "ios-components",
  version: "1.0.0"
});

// Tool: list_components
// Returns all available components with brief descriptions
server.tool(
  "list_components",
  "List all available iOS UIKit components with their descriptions",
  {},
  async () => {
    try {
      const res = await fetch(`${GITHUB_BASE}/index.json`);
      if (!res.ok) {
        return {
          content: [{
            type: "text",
            text: `Failed to fetch component index: ${res.status} ${res.statusText}`
          }]
        };
      }
      const data = await res.json();
      return {
        content: [{
          type: "text",
          text: JSON.stringify(data.components, null, 2)
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: "text",
          text: `Error fetching components: ${error.message}`
        }]
      };
    }
  }
);

// Tool: get_component
// Returns full specification for a single component
server.tool(
  "get_component",
  "Get full specification for an iOS component including properties, usage examples, and tags",
  {
    name: {
      type: "string",
      description: "Component name (e.g., ChipsView, ContextMenuView)",
      required: true
    }
  },
  async ({ name }) => {
    try {
      const res = await fetch(`${GITHUB_BASE}/components/${name}.json`);
      if (!res.ok) {
        return {
          content: [{
            type: "text",
            text: `Component "${name}" not found. Use list_components to see available components.`
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
    } catch (error) {
      return {
        content: [{
          type: "text",
          text: `Error fetching component "${name}": ${error.message}`
        }]
      };
    }
  }
);

// Tool: search_components
// Search components by name, description, or tags
server.tool(
  "search_components",
  "Search for iOS components by keyword (matches name, description, or tags)",
  {
    query: {
      type: "string",
      description: "Search query (e.g., 'filter', 'menu', 'avatar')",
      required: true
    }
  },
  async ({ query }) => {
    try {
      const res = await fetch(`${GITHUB_BASE}/index.json`);
      if (!res.ok) {
        return {
          content: [{
            type: "text",
            text: `Failed to fetch component index: ${res.status} ${res.statusText}`
          }]
        };
      }
      const data = await res.json();
      const q = query.toLowerCase();

      // Search in index first
      const matches = data.components.filter(c =>
        c.name.toLowerCase().includes(q) ||
        c.description.toLowerCase().includes(q)
      );

      if (matches.length === 0) {
        return {
          content: [{
            type: "text",
            text: `No components found matching "${query}". Use list_components to see all available components.`
          }]
        };
      }

      return {
        content: [{
          type: "text",
          text: JSON.stringify(matches, null, 2)
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: "text",
          text: `Error searching components: ${error.message}`
        }]
      };
    }
  }
);

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);
