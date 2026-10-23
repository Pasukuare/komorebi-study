#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON_ROOT="$PROJECT_ROOT/DesignProposals/Identity-D-Final"
ICON_TEMP="$(mktemp -d)"
trap 'rm -rf "$ICON_TEMP"' EXIT
python3 "$ICON_ROOT/genera.py"
swiftc -module-cache-path "$ICON_TEMP/modules" "$PROJECT_ROOT/Scripts/Icon.swift" -o "$ICON_TEMP/render"
python3 - "$ICON_ROOT" "$ICON_TEMP/render" <<'PY'
from pathlib import Path
import subprocess,shutil,sys
root=Path(sys.argv[1]);renderer=sys.argv[2]
for points in [16,32,128,256,512]:
    for scale in [1,2]:
        name=f'icon_{points}x{points}'+('@2x' if scale==2 else '')+'.png'
        dest=root/'AppIcon.iconset'/name
        subprocess.run([renderer,str(dest),str(root/'icona-D-chiara-1024.svg'),str(points*scale)],check=True)
        shutil.copy2(dest,root/'AppIcon.appiconset'/name)
shutil.copy2(root/'AppIcon.iconset/icon_512x512@2x.png',root/'icona-D-chiara-1024.png')
PY
python3 "$ICON_ROOT/pack-icns.py"
cp "$ICON_ROOT/AppIcon.icns" "$PROJECT_ROOT/Resources/AppIcon.icns"
