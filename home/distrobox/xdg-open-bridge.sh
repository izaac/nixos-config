#!/bin/sh
if [ ! -f /usr/local/bin/xdg-open ]; then
  printf '#!/bin/sh\nexec distrobox-host-exec xdg-open "$@"\n' | sudo tee /usr/local/bin/xdg-open >/dev/null
  sudo chmod +x /usr/local/bin/xdg-open
fi
if [ ! -f /usr/local/bin/opencode ]; then
  printf '#!/bin/sh\nexec distrobox-host-exec opencode "$@"\n' | sudo tee /usr/local/bin/opencode >/dev/null
  sudo chmod +x /usr/local/bin/opencode
fi
