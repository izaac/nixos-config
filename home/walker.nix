# Walker — GNOME-Activities-style dashboard launcher (apps grid, scrollable,
# Stylix-themed). Bound to Mod+Space in niri. Coexists with fuzzel (Mod+D).
{
  config,
  pkgs,
  ...
}: let
  c = config.lib.stylix.colors;
in {
  # Walker 2.x is split into three parts: the `walker` UI client, the
  # `walker --gapplication-service` UI daemon, and the `elephant` data
  # backend. Both daemons are declared as HM systemd user services below,
  # tied to graphical-session.target. They auto-start on login, restart
  # on failure, and survive niri respawns (unlike niri spawn-at-startup
  # which leaves orphans if the compositor crashes and re-runs).
  home.packages = [pkgs.walker pkgs.elephant];

  # Niri session definitions. Triggered from walker → "Current Layout".
  # Uses proportional column widths so it survives monitor swaps.
  # Workspace 1: Brave (≈70%) + Ghostty (≈30%) side by side.
  xdg.configFile."elephant/nirisessions.toml".text = ''
    [[sessions]]
    name = "Daily"

    [[sessions.workspaces]]
    # Brave (70%) + Ghostty (30%) side by side. After all windows spawn,
    # focus the first column so Brave is active.
    # Commands wrapped in `systemd-run --user --no-block --collect --` so
    # each spawn becomes a child of systemd user manager, not elephant.
    # This makes them survive `systemctl --user restart elephant walker`.
    windows = [
      { command = "systemd-run --user --no-block --collect -- brave-origin", app_id = "brave-origin", after = [
        "niri msg action set-column-width '70%'",
      ] },
      { command = "systemd-run --user --no-block --collect -- ghostty", app_id = "com.mitchellh.ghostty", after = [
        "niri msg action set-column-width '30%'",
      ] },
    ]
    after = [
      "niri msg action focus-column-first",
    ]
  '';

  # Elephant config — restrict which providers get loaded into memory.
  # Each provider indexed costs roughly 10-25 MB resident; trimming the
  # full auto-load set down to three cuts elephant's working set by
  # ~80-120 MB.
  # KEEP: desktopapplications (core grid), windows (alt-tab style focus),
  # nirisessions (saved layouts). Drop the rest.
  xdg.configFile."elephant/elephant.toml".text = ''
    # Wrap every spawn in a systemd transient service unit so launched apps
    # survive walker/elephant daemon restarts. Service mode (no --scope)
    # detaches the process from the launcher entirely; --no-block returns
    # immediately, --collect garbage-collects the unit after the app exits.
    launch_prefix = "systemd-run --user --no-block --collect --"

    ignored_providers = [
      "providerlist",
      "niriactions",
      "wireplumber",
      "symbols",
      "playerctl",
      "unicode",
      "clipboard",
      "bluetooth",
      "snippets",
      "websearch",
      "bookmarks",
      "archlinuxpkgs",
      "runner",
      "calc",
      "todo",
      "files",
    ]
  '';

  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant data backend for the Walker launcher";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.elephant}/bin/elephant";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  systemd.user.services.walker = {
    Unit = {
      Description = "Walker launcher UI daemon (Mod+Space)";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target" "elephant.service"];
      Wants = ["elephant.service"];
    };
    Service = {
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  # Top-level walker config selects the "stylix" theme defined below.
  xdg.configFile."walker/config.toml".text = ''
    theme = "stylix"

    [app_launch_prefix]
    prefix = ""

    [activation_mode]
    disabled = true

    [builtins.applications]
    weight = 5
    icon_size = 64
    hide_actions_with_empty_query = true
  '';

  # Walker themes are directories of GTK4 XML + CSS that inherit from
  # the upstream "default" theme. Our "stylix" theme overrides:
  #   - layout.xml: switch GtkGridView from 1-column list to 6-column
  #                 grid (GNOME-Activities feel) and enlarge the window
  #   - style.css : Stylix base16 palette with 90% bg opacity
  xdg.configFile."walker/themes/stylix/layout.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <interface>
      <requires lib="gtk" version="4.0"></requires>
      <object class="GtkWindow" id="Window">
        <style>
          <class name="window"></class>
        </style>
        <property name="resizable">true</property>
        <property name="title">Walker</property>
        <child>
          <object class="GtkBox" id="BoxWrapper">
            <style>
              <class name="box-wrapper"></class>
            </style>
            <property name="overflow">hidden</property>
            <property name="orientation">horizontal</property>
            <property name="valign">center</property>
            <property name="halign">center</property>
            <property name="width-request">1200</property>
            <property name="height-request">700</property>
            <child>
              <object class="GtkBox" id="Box">
                <style>
                  <class name="box"></class>
                </style>
                <property name="orientation">vertical</property>
                <property name="hexpand-set">true</property>
                <property name="hexpand">true</property>
                <property name="spacing">10</property>
                <child>
                  <object class="GtkBox" id="SearchContainer">
                    <style>
                      <class name="search-container"></class>
                    </style>
                    <property name="overflow">hidden</property>
                    <property name="orientation">horizontal</property>
                    <property name="halign">fill</property>
                    <property name="hexpand-set">true</property>
                    <property name="hexpand">true</property>
                    <child>
                      <object class="GtkEntry" id="Input">
                        <style>
                          <class name="input"></class>
                        </style>
                        <property name="halign">fill</property>
                        <property name="hexpand-set">true</property>
                        <property name="hexpand">true</property>
                      </object>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkBox" id="ContentContainer">
                    <style>
                      <class name="content-container"></class>
                    </style>
                    <property name="orientation">horizontal</property>
                    <property name="spacing">10</property>
                    <child>
                      <object class="GtkLabel" id="ElephantHint">
                        <style>
                          <class name="elephant-hint"></class>
                        </style>
                        <property name="label">Waiting for elephant...</property>
                        <property name="hexpand">true</property>
                        <property name="vexpand">true</property>
                        <property name="visible">false</property>
                        <property name="valign">0.5</property>
                      </object>
                    </child>
                    <child>
                      <object class="GtkLabel" id="Placeholder">
                        <style>
                          <class name="placeholder"></class>
                        </style>
                        <property name="label">No Results</property>
                        <property name="hexpand">true</property>
                        <property name="vexpand">true</property>
                        <property name="valign">0.5</property>
                      </object>
                    </child>
                    <child>
                      <object class="GtkScrolledWindow" id="Scroll">
                        <style>
                          <class name="scroll"></class>
                        </style>
                        <property name="can_focus">false</property>
                        <property name="overlay-scrolling">true</property>
                        <property name="hexpand">true</property>
                        <property name="vexpand">true</property>
                        <property name="max-content-width">1140</property>
                        <property name="min-content-width">1140</property>
                        <property name="max-content-height">600</property>
                        <property name="propagate-natural-height">true</property>
                        <property name="propagate-natural-width">true</property>
                        <property name="hscrollbar-policy">never</property>
                        <property name="vscrollbar-policy">automatic</property>
                        <child>
                          <object class="GtkGridView" id="List">
                            <style>
                              <class name="list"></class>
                            </style>
                            <property name="max_columns">4</property>
                            <property name="min_columns">4</property>
                            <property name="can_focus">false</property>
                          </object>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkBox" id="Preview">
                        <style>
                          <class name="preview"></class>
                        </style>
                      </object>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkBox" id="Keybinds">
                    <property name="hexpand">true</property>
                    <property name="margin-top">10</property>
                    <style>
                      <class name="keybinds"></class>
                    </style>
                    <child>
                      <object class="GtkBox" id="GlobalKeybinds">
                        <property name="spacing">10</property>
                        <style>
                          <class name="global-keybinds"></class>
                        </style>
                      </object>
                    </child>
                    <child>
                      <object class="GtkBox" id="ItemKeybinds">
                        <property name="hexpand">true</property>
                        <property name="halign">end</property>
                        <property name="spacing">10</property>
                        <style>
                          <class name="item-keybinds"></class>
                        </style>
                      </object>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkLabel" id="Error">
                    <style>
                      <class name="error"></class>
                    </style>
                    <property name="xalign">0</property>
                    <property name="visible">false</property>
                  </object>
                </child>
              </object>
            </child>
          </object>
        </child>
      </object>
    </interface>
  '';

  # Stylix base16 palette baked into the walker CSS. layout.xml sets style
  # CLASSES on widgets (via <class name="...">) so selectors here use the
  # `.class` form. Inner containers are forced transparent so the only
  # background layer is `.box` (90% opaque, alpha 0xe6 ≈ 230/255).
  xdg.configFile."walker/themes/stylix/style.css".text = ''
    window,
    .window,
    .box-wrapper,
    .content-container,
    .scroll,
    .scroll > * ,
    .list,
    .preview,
    .keybinds,
    .global-keybinds,
    .item-keybinds {
      background-color: transparent;
      background: transparent;
    }

    .box {
      background-color: #${c.base00}e6;
      border: 2px solid #${c.base0D};
      border-radius: 16px;
      padding: 16px;
    }

    .search-container {
      background-color: #${c.base01};
      border-radius: 8px;
      padding: 4px 12px;
      margin-bottom: 12px;
    }

    .input {
      color: #${c.base05};
      background: transparent;
      border: none;
      font-size: 16px;
      caret-color: #${c.base0D};
    }

    .list child {
      padding: 12px;
      margin: 4px;
      border-radius: 10px;
      background-color: transparent;
      color: #${c.base05};
    }

    .list child:hover {
      background-color: #${c.base01};
    }

    .list child:selected,
    .list child:focus {
      background-color: #${c.base02};
    }

    .icon {
      -gtk-icon-size: 64px;
    }

    .label {
      color: #${c.base05};
      font-size: 13px;
    }

    .sub {
      color: #${c.base04};
      font-size: 11px;
    }

    .placeholder,
    .elephant-hint {
      color: #${c.base04};
    }
  '';
}
