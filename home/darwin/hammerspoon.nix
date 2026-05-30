# Hammerspoon — Lua-driven macOS automation.
#
# Sole job here: watch for Moonlight launch/quit and tune the host for low-
# latency game streaming while it's open. Hammerspoon itself stays resident
# (~20 MB, menu-bar icon disabled), but the side effects only fire while
# Moonlight is running, so the system is otherwise untouched.
#
# What the watcher does on Moonlight launch:
#   - Starts `caffeinate -di` to block display + idle sleep for the stream.
#   - SIGSTOPs the user-owned analyzer daemons (photoanalysisd, mediaanalysisd,
#     cloudphotod) that otherwise burn CPU/GPU/network in the background.
#   - Optionally toggles a user-defined Focus via Shortcuts.app (off by
#     default; see FOCUS_NAME).
# On quit: reverses all of it (SIGCONT to resume the daemons).
#
# One-time setup (cannot be declared from Nix):
#   1. Open Hammerspoon once, grant Accessibility permission in System
#      Settings → Privacy & Security → Accessibility.
#   2. (Optional) Create two Shortcuts named "Enable Gaming" and
#      "Disable Gaming" that toggle a Focus, then flip FOCUS_NAME below.
_: {
  # Drop the init.lua declaratively. Editing it by hand would be overwritten
  # on the next home-manager activation; treat this Nix file as source of truth.
  home.file.".hammerspoon/init.lua".text = ''
    -- Managed by nix-darwin / home-manager (home/darwin/hammerspoon.nix).
    -- Edits here are clobbered on the next activation.

    local TARGET_APP = "Moonlight"
    local FOCUS_NAME = nil  -- set to "Gaming" once the Shortcuts exist

    -- User-owned background daemons paused while Moonlight is open. Confirmed
    -- on macOS 26 (Tahoe) running as the login user, so pkill -x without sudo
    -- can signal them. SIGCONT on quit lets them catch up after the stream.
    -- mds / mds_stores remain root-owned and untouched.
    local PAUSED_DAEMONS = {
      "photoanalysisd",            -- Photos library scene/face analysis
      "mediaanalysisd",            -- Visual Lookup, media intelligence
      "mediaanalysisd-access",     -- XPC sibling of mediaanalysisd
      "cloudphotod",               -- iCloud Photos sync
      "mdworker_shared",           -- on-demand Spotlight indexer
      "corespotlightd",            -- Core Spotlight (Notes/Mail search)
      "managedcorespotlightd",     -- managed Core Spotlight index
      "spotlightknowledged",       -- Spotlight knowledge graph
      "spotlightknowledged.updater", -- ML model updater
      -- Skipped on purpose: bird (iCloud Drive can hang file opens),
      -- distnoted (system notification bus — many apps depend on it).
    }

    hs.autoLaunch(true)
    hs.menuIcon(false)
    hs.dockIcon(false)

    local log = hs.logger.new("moonlight", "info")
    local caffeinate = nil

    local function startCaffeinate()
      if caffeinate then return end
      -- -d: block display sleep, -i: block idle sleep. Stays alive for the
      -- whole stream; killed on Moonlight quit below.
      caffeinate = hs.task.new("/usr/bin/caffeinate", function()
        caffeinate = nil
      end, {"-di"})
      caffeinate:start()
      log.i("caffeinate -di started")
    end

    local function stopCaffeinate()
      if not caffeinate then return end
      caffeinate:terminate()
      caffeinate = nil
      log.i("caffeinate stopped")
    end

    local function signalDaemons(sig)
      for _, name in ipairs(PAUSED_DAEMONS) do
        -- pkill returns nonzero if no match; we don't care, hence no callback.
        hs.task.new("/usr/bin/pkill", nil, {"-" .. sig, "-x", name}):start()
      end
      log.i("daemons " .. sig)
    end

    local function runShortcut(name)
      if not name then return end
      hs.task.new("/usr/bin/shortcuts", nil, {"run", name}):start()
    end

    local function focusOn()
      if FOCUS_NAME then runShortcut("Enable " .. FOCUS_NAME) end
    end

    local function focusOff()
      if FOCUS_NAME then runShortcut("Disable " .. FOCUS_NAME) end
    end

    local watcher = hs.application.watcher.new(function(name, event, app)
      if name ~= TARGET_APP then return end
      if event == hs.application.watcher.launched then
        log.i(TARGET_APP .. " launched")
        startCaffeinate()
        signalDaemons("STOP")
        focusOn()
      elseif event == hs.application.watcher.terminated then
        log.i(TARGET_APP .. " terminated")
        stopCaffeinate()
        signalDaemons("CONT")
        focusOff()
      end
    end)
    watcher:start()

    -- Cover the case where Hammerspoon (re)starts while Moonlight is already
    -- open — otherwise caffeinate would never fire for that session.
    if hs.application.find(TARGET_APP) then
      startCaffeinate()
      signalDaemons("STOP")
      focusOn()
    end
  '';
}
