# Sysprite × Sketchybar

Drop these into your sketchybar config to render Sysprite stats as native sketchybar items.

## How it works

The Sysprite app writes a JSON snapshot to
`~/Library/Application Support/Sysprite/snapshot.json` every second. The
`sysprite stats` subcommand reads that file:

```bash
sysprite stats --json       # full snapshot
sysprite stats --pressure   # 0–100 combined pressure
sysprite stats --cpu        # CPU %
sysprite stats --memory     # Memory %
sysprite stats --net-down   # download bytes/sec
sysprite stats --net-up     # upload bytes/sec
sysprite stats --battery    # battery %
```

So a sketchybar plugin is just a one-liner.

## Install

1. Build & install Sysprite (`make install` in the repo root). The app must be running.
2. Symlink the binary so sketchybar can find it on PATH:
   ```bash
   sudo ln -sf /Applications/Sysprite.app/Contents/MacOS/Sysprite /usr/local/bin/sysprite
   ```
3. Copy `sysprite.sh` into your sketchybar plugins dir (typically `~/.config/sketchybar/plugins/`).
4. Add the snippet from `sketchybarrc.example` to your `~/.config/sketchybar/sketchybarrc`.
5. `sketchybar --reload`

## Files

- `sysprite.sh` — plugin script. Reads `sysprite stats --json` and updates a sketchybar item with CPU/MEM/pressure.
- `sketchybarrc.example` — example item declaration showing two variants (combined and split).
