# Themes

Each subdirectory here becomes a selectable theme in the menu bar app.

Drop a folder of numbered PNG frames into this directory and rebuild:

```
Resources/Themes/cat/
  frame_00.png
  frame_01.png
  frame_02.png
  ...
```

Frame requirements:

- PNG, square or near-square, ideally 22×22 or 44×44 px (1x / 2x retina pair)
- Transparent background
- Pure white or black silhouettes work best — files are loaded as **template images**, so macOS will tint them to match the menu bar appearance
- Frames are played in filename sort order, so use zero-padded names

If this directory is empty when the app starts, a procedurally-drawn cat falls back automatically.

## Suggested CC0 sprite sources

- https://opengameart.org/ (filter for CC0)
- https://itch.io/game-assets/free (check license)
- https://kenney.nl/assets

Make sure you ship the original license file alongside any sprites you bundle.
