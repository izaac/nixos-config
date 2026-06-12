# AeroSpace — i3-like tiling WM for macOS (no SIP changes required).
# Mac-only: imported from hosts/Mac/configuration.nix, NOT from the shared
# home/core.nix (programs.aerospace is a Darwin module and would break Linux).
#
# Modifier is Alt (Option), not Super/Cmd: Cmd is reserved by macOS apps
# (Cmd+Q/W/1-9 etc.), so the niri "Mod+" muscle memory maps to "alt+" here.
# Keybinds mirror home/niri.nix: hjkl focus, Shift+hjkl move, Alt+1-9 workspace,
# Alt+Shift+1-9 move-to-workspace, Alt+PgUp/PgDn switch workspace.
{config, ...}: {
  programs.aerospace = {
    enable = true;
    # Run and supervise AeroSpace via a Home Manager launchd agent so it starts
    # at login and restarts if it dies.
    launchd.enable = true;

    settings = {
      # Match niri: no macOS Spaces animation, gaps of 8px.
      gaps = {
        inner = {
          horizontal = 8;
          vertical = 8;
        };
        outer = {
          left = 8;
          right = 8;
          top = 8;
          bottom = 8;
        };
      };

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      accordion-padding = 30;

      # Float dialogs/utilities instead of tiling them (mirrors niri's
      # open-floating window-rules). Tunnelblick's small VPN windows included.
      on-window-detected = [
        {
          "if".app-id = "com.apple.systempreferences";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.calculator";
          run = "layout floating";
        }
        {
          "if".app-id = "net.tunnelblick.tunnelblick";
          run = "layout floating";
        }
        {
          # Float Moonlight so AeroSpace doesn't tile it. With layout=floating
          # the user can hit Cmd+Ctrl+F (or Moonlight's built-in fullscreen) to
          # enter macOS native fullscreen — that gives direct scanout and the
          # lowest possible input lag for the stream.
          "if".app-id = "com.moonlight-stream.Moonlight";
          run = "layout floating";
        }
      ];

      mode.main.binding = {
        # --- Apps ---
        # Launch the Home Manager-managed kitty.app explicitly: a leftover
        # manually-installed /Applications/kitty.app would otherwise be an
        # ambiguous `open -na kitty` target.
        alt-enter = "exec-and-forget open -na '${config.home.homeDirectory}/Applications/Home Manager Apps/kitty.app'";

        # --- Focus (vim hjkl + Ctrl+Option+Arrow) ---
        # Arrows use Ctrl+Option, NOT plain Option: Option+Arrow /
        # Option+Shift+Arrow are macOS word-motion and word-selection in text
        # fields, terminals, and text areas, so we leave those free. Modifier
        # order follows AeroSpace's cmd-alt-ctrl-shift convention.
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";
        alt-ctrl-left = "focus left";
        alt-ctrl-down = "focus down";
        alt-ctrl-up = "focus up";
        alt-ctrl-right = "focus right";

        # --- Move window ---
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";
        alt-ctrl-shift-left = "move left";
        alt-ctrl-shift-down = "move down";
        alt-ctrl-shift-up = "move up";
        alt-ctrl-shift-right = "move right";

        # --- Layout / size ---
        alt-f = "fullscreen";
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";
        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        # --- Window/session ---
        alt-q = "close";

        # --- Workspaces (Alt+1-9, like niri Mod+1-9) ---
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";

        # --- Move column to workspace (Alt+Shift+1-9) ---
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";

        # --- Workspace next/prev ---
        # On the built-in MacBook keyboard there are no physical PageUp/PageDown
        # keys (they are Fn+Up / Fn+Down), so Alt+1-9 above is the day-to-day
        # workspace nav. These mirror niri's Mod+PageDown/Up and are handy on an
        # external keyboard; alt-tab toggles the last workspace (laptop-friendly).
        alt-pageDown = "workspace --wrap-around next";
        alt-pageUp = "workspace --wrap-around prev";
        alt-tab = "workspace-back-and-forth";

        # --- Service mode (reload config, etc.) ---
        alt-shift-semicolon = "mode service";
      };

      # Service mode: Alt+Shift+; enters it; these keys act, then return to main.
      mode.service.binding = {
        esc = ["reload-config" "mode main"];
        r = ["flatten-workspace-tree" "mode main"]; # reset layout
        f = ["layout floating tiling" "mode main"]; # toggle float
        backspace = ["close-all-windows-but-current" "mode main"];
      };
    };
  };
}
