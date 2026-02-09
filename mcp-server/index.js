#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { execSync } from "child_process";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "..");

function git(cmd) {
  return execSync(cmd, { cwd: REPO_ROOT, encoding: "utf-8", timeout: 15000 }).trim();
}

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

      const log = git('git log --format="%h %s (%an, %cr)" main..origin/main');

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

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);
