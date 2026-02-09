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
  local filter_prefix="$3"

  # Check repo exists
  if [ ! -d "$repo_path/.git" ]; then
    echo "${label}: ?"
    return
  fi

  # Check cache freshness
  local now
  now=$(date +%s)
  local needs_fetch=1

  if [ -f "${CACHE_DIR}/${label}.ts" ]; then
    local last_fetch
    last_fetch=$(cat "${CACHE_DIR}/${label}.ts")
    if [ $((now - last_fetch)) -lt $CACHE_TTL ]; then
      needs_fetch=0
    fi
  fi

  # Fetch if needed (with 3-second timeout)
  if [ $needs_fetch -eq 1 ]; then
    git -C "$repo_path" fetch origin main --quiet 2>/dev/null &
    local fetch_pid=$!
    local waited=0
    while kill -0 $fetch_pid 2>/dev/null && [ $waited -lt 6 ]; do
      sleep 0.5
      waited=$((waited + 1))
    done
    kill $fetch_pid 2>/dev/null
    wait $fetch_pid 2>/dev/null
    echo "$now" > "${CACHE_DIR}/${label}.ts"
  fi

  # Count divergence
  local behind
  behind=$(git -C "$repo_path" rev-list --count main..origin/main 2>/dev/null || echo "0")

  if [ "$behind" = "0" ]; then
    echo "${label}: ✓"
    return
  fi

  # Count new and modified relevant files
  local new_count=0
  local mod_count=0

  if [ -n "$filter_prefix" ]; then
    new_count=$(git -C "$repo_path" diff --name-only --diff-filter=A main..origin/main 2>/dev/null | grep -c "$filter_prefix" || true)
    mod_count=$(git -C "$repo_path" diff --name-only --diff-filter=M main..origin/main 2>/dev/null | grep -c "$filter_prefix" || true)
  else
    new_count=$(git -C "$repo_path" diff --name-only --diff-filter=A main..origin/main 2>/dev/null | wc -l | tr -d ' ')
    mod_count=$(git -C "$repo_path" diff --name-only --diff-filter=M main..origin/main 2>/dev/null | wc -l | tr -d ' ')
  fi

  # Time since last remote commit (shortened)
  local ago
  ago=$(git -C "$repo_path" log -1 --format=%cr origin/main 2>/dev/null || echo "?")
  ago=$(echo "$ago" | sed 's/ seconds\{0,1\} ago/s/;s/ minutes\{0,1\} ago/m/;s/ hours\{0,1\} ago/h/;s/ days\{0,1\} ago/d/;s/ weeks\{0,1\} ago/w/')

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
result=""
for i in "${!status_parts[@]}"; do
  if [ $i -gt 0 ]; then result="${result} | "; fi
  result="${result}${status_parts[$i]}"
done
printf '%s' "$result"
