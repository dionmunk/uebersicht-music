#!/bin/bash
# Feeds the music widget. On first run, renders the transport-control SF Symbols
# to PNG masks, and the installed music apps' icons (for the square-layout badge),
# with the Swift helpers (neither set is shipped); then emits the current track
# via getMusicData.applescript. Requires Xcode Command Line Tools.
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$DIR/icons/play.fill.ink.png" ]; then
  mkdir -p "$DIR/icons"
  swift "$DIR/render-controls.swift" "$DIR/icons" >/dev/null 2>&1
fi
if [ ! -f "$DIR/icons/app-music.png" ]; then
  mkdir -p "$DIR/icons"
  swift "$DIR/render-appicons.swift" "$DIR/icons" >/dev/null 2>&1
fi

osascript "$DIR/getMusicData.applescript"
