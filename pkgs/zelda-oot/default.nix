{ pkgs, ... }:

pkgs.writeShellScriptBin "launch-zelda-oot" ''
  GAME_DIR="$HOME/Games/ZeldaOOT"
  DWARFS_IMG="$GAME_DIR/files/game-root.dwarfs"
  MNT_BASE="$GAME_DIR/.mounts/base"
  MNT_FINAL="$GAME_DIR/.mounts/final"
  WRITABLE="$GAME_DIR/Saves"
  WORKDIR="$GAME_DIR/.mounts/work"

  if [ ! -f "$DWARFS_IMG" ]; then
    echo "Error: Game data not found in $GAME_DIR"
    if command -v notify-send >/dev/null; then
      ${pkgs.libnotify}/bin/notify-send "Zelda OOT Error" "Game data not found in $GAME_DIR. Please copy the folder to ~/Games/ZeldaOOT" --icon=error
    fi
    exit 1
  fi

  chmod -R +w "$GAME_DIR"
  [ -f "$GAME_DIR/files/dwarfs-binary" ] && chmod +x "$GAME_DIR/files/dwarfs-binary"

  mkdir -p "$MNT_BASE" "$MNT_FINAL" "$WRITABLE" "$WORKDIR"

  if ! mountpoint -q "$MNT_BASE"; then
      ${pkgs.dwarfs}/bin/dwarfs "$DWARFS_IMG" "$MNT_BASE" -o allow_other
  fi

  if ! mountpoint -q "$MNT_FINAL"; then
      ${pkgs.fuse-overlayfs}/bin/fuse-overlayfs -o lowerdir="$MNT_BASE",upperdir="$WRITABLE",workdir="$WORKDIR" "$MNT_FINAL"
  fi

  cd "$MNT_FINAL"
  ${pkgs.steam-run}/bin/steam-run ./usr/bin/soh.elf

  cd "$GAME_DIR"
  ${pkgs.fuse}/bin/fusermount3 -u "$MNT_FINAL"
  ${pkgs.fuse}/bin/fusermount3 -u "$MNT_BASE"
''
