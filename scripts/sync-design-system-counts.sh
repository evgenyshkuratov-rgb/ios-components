#!/bin/bash
# Called by Xcode "Sync Design System Counts" build phase.
# SRCROOT is set by Xcode (= GalleryApp directory).

ICONS_REPO="${ICONS_REPO_PATH:-$HOME/Clode code projects/Icons library}"
COMPS_ROOT="${SRCROOT:-.}/.."
OUT="${SRCROOT:-.}/GalleryApp/Resources/design-system-counts.json"
CACHE=/tmp/.gallery-sync-stamp
MAX_AGE=600

# Pull only if last sync was >10 min ago
need_pull=0
if [ ! -f "$CACHE" ]; then
  need_pull=1
else
  age=$(( $(date +%s) - $(stat -f %m "$CACHE") ))
  [ $age -gt $MAX_AGE ] && need_pull=1
fi

if [ $need_pull -eq 1 ]; then
  git -C "$ICONS_REPO" pull --ff-only 2>/dev/null || true
  git -C "$COMPS_ROOT" pull --ff-only 2>/dev/null || true
  touch "$CACHE"
fi

python3 << 'PYEOF'
import json, os, subprocess

icons_repo = os.path.expanduser('~/Clode code projects/Icons library')
srcroot = os.environ.get('SRCROOT', '.')
comps_root = os.path.abspath(os.path.join(srcroot, '..'))
out = os.path.join(srcroot, 'GalleryApp/Resources/design-system-counts.json')

data = {}

try:
    with open(os.path.join(icons_repo, 'metadata.json')) as f:
        data['icons'] = len(json.load(f).get('icons', []))
except Exception:
    data['icons'] = 0

try:
    with open(os.path.join(icons_repo, 'colors.json')) as f:
        data['colors'] = len(json.load(f).get('colors', []))
except Exception:
    data['colors'] = 0

try:
    with open(os.path.join(comps_root, 'specs/index.json')) as f:
        data['components'] = len(json.load(f).get('components', []))
except Exception:
    data['components'] = 0

def git_date(repo, paths):
    try:
        args = ['git', '-C', repo, 'log', '-1', '--format=%aI', '--'] + paths
        result = subprocess.check_output(args, stderr=subprocess.DEVNULL).decode().strip()
        return result or None
    except Exception:
        return None

data['icons_updated'] = git_date(icons_repo, ['icons/'])
data['colors_updated'] = git_date(icons_repo, ['colors.json'])
data['components_updated'] = git_date(comps_root, ['Sources/', 'specs/'])

with open(out, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
PYEOF
