# Toggle mount/unmount for rclone ul-crypt.
# Uses osascript for admin privileges (GUI password dialog) and notifications.
# Designed to run headlessly from a .app bundle — no terminal window needed.

MOUNT_NAME="Encrypted Drive"
VOLUME="/Volumes/$MOUNT_NAME"
REMOTE="ul-crypt:"

if mount | grep -q "$VOLUME"; then
  umount "$VOLUME" 2>/dev/null || diskutil unmount "$VOLUME" 2>/dev/null
  osascript -e "do shell script \"rmdir '$VOLUME'\" with administrator privileges" 2>/dev/null
  osascript -e 'display notification "Encrypted drive unmounted" with title "rclone"'
else
  # GUI password prompt via osascript instead of sudo
  osascript -e "do shell script \"mkdir -p '$VOLUME' && chown $USER '$VOLUME'\" with administrator privileges" || exit 1
  rclone mount "$REMOTE" "$VOLUME" \
    --volname "$MOUNT_NAME" \
    --vfs-cache-mode full \
    --vfs-cache-max-size 10G \
    --vfs-cache-max-age 24h \
    --dir-cache-time 72h \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 1G \
    --buffer-size 32M \
    --no-modtime &
  # Wait up to 10 seconds for the FUSE mount to appear
  for _ in $(seq 1 10); do
    sleep 1
    if mount | grep -q "$VOLUME"; then
      osascript -e 'display notification "Encrypted drive mounted" with title "rclone"'
      open "$VOLUME"
      exit 0
    fi
  done
  osascript -e 'display notification "Mount failed — check rclone config" with title "rclone"'
  exit 1
fi
