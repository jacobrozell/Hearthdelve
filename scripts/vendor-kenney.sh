#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
SRC="${KENNEY_ROOT:-$HOME/Desktop/personal/Kenney Game Assets All-in-1 3.7.0}"
ART="$ROOT/Art/vendor/kenney"
AUDIO="$ROOT/Audio/vendor/kenney"

copy_pack() {
  mkdir -p "$2"
  rsync -a --delete --exclude '.DS_Store' --exclude '*.url' "$1/" "$2/"
}

copy_pack "$SRC/2D assets/Tiny Dungeon" "$ART/tiny-dungeon"
copy_pack "$SRC/2D assets/Tiny Town" "$ART/tiny-town"
copy_pack "$SRC/2D assets/Tiny Farm" "$ART/tiny-farm"
copy_pack "$SRC/2D assets/Tiny Battle" "$ART/tiny-battle"
copy_pack "$SRC/2D assets/Roguelike Characters Pack" "$ART/roguelike-characters"
copy_pack "$SRC/2D assets/Roguelike Base Pack" "$ART/roguelike-base"
copy_pack "$SRC/2D assets/Roguelike Dungeon Pack" "$ART/roguelike-dungeon"
copy_pack "$SRC/2D assets/Roguelike Interior Pack" "$ART/roguelike-interior"
copy_pack "$SRC/2D assets/1-Bit Pack" "$ART/1-bit"
copy_pack "$SRC/2D assets/Emote Pack" "$ART/emote"
copy_pack "$SRC/2D assets/Light Masks" "$ART/light-masks"
copy_pack "$SRC/UI assets/UI Pack - Pixel Adventure" "$ART/ui-pixel-adventure"
copy_pack "$SRC/UI assets/UI Pixel Pack" "$ART/ui-pixel"
copy_pack "$SRC/UI assets/Cursor Pixel Pack" "$ART/cursor-pixel"
copy_pack "$SRC/Other/Fonts" "$ART/fonts"
copy_pack "$SRC/Audio/Interface Sounds" "$AUDIO/interface-sounds"
copy_pack "$SRC/Audio/Impact Sounds" "$AUDIO/impact-sounds"
copy_pack "$SRC/Audio/RPG Audio" "$AUDIO/rpg-audio"
copy_pack "$SRC/Audio/Music Jingles" "$AUDIO/music-jingles"
