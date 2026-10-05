# Themes, Visor and Earthrise

A theme is a folder in the rice, not in this repo:

```
~/.config/theme/
  themes/<name>/
    theme.json            { "name": "...", "main_wallpaper": "a.png", "wallpapers": ["b.jpg"] }
    palette.json          the theme's colours
    wallpapers/           only the files theme.json lists are used
  palette.json            the current theme's palette, which everything reads
```

**Visor** picks the current theme and **Earthrise** picks a wallpaper from the current
theme. Both are a carousel in the middle of the focused monitor: the current card is large
and its neighbours peek out on each side. Left, Right and Tab move, Enter chooses, Escape
or a click outside closes. A Visor card is the theme's main wallpaper with its name and
colours under it, outlined in the theme's accent.

- The cards show small JPEG previews, made in the background when Apollo starts and
  whenever a wallpaper is added or changed, so the pictures are there as soon as the
  carousel opens. They live in `previews/` in Quickshell's cache directory
  (`~/.cache/quickshell/by-shell/<id>/previews`) and can be deleted at any time; the cards
  then show the full pictures until the previews are made again. Setting a wallpaper always
  uses the original file.
- Choosing a theme copies its `palette.json` over `~/.config/theme/palette.json`, runs
  `themeApplyCommand` to recolour the rest of the rice, and sets the main wallpaper.
- Apollo takes its own colours from `~/.config/theme/palette.json` (`bg`, `fg`, `accent`,
  `regular1` for warnings; the greys are mixed from `bg` and `fg`) and follows the file when
  it changes. Without that file it uses the colours in `qml/core/Theme.qml`.
- Wallpapers are set with `wallpaperCommand`, `awww img <file>` by default.
