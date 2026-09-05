# smug: declarative tmux session layouts. Go binary, no Ruby or Python
# runtime, unlike tmuxinator and tmuxp.
#
# Usage: `smug start daily`, `smug stop daily`, `smug list`.
{
  pkgs,
  config,
  lib,
  ...
}: let
  home = config.home.homeDirectory;

  # Every window is two panes side by side. smug's `panes` list holds the
  # panes created *in addition* to the one tmux opens with a window, so a
  # single entry yields two panes, and even-horizontal splits them left/right.
  mkWindow = {
    name,
    root,
  }: {
    inherit name root;
    layout = "even-horizontal";
    panes = [{commands = [];}];
  };

  daily = {
    session = "daily";
    root = "${home}/repos";
    windows = map mkWindow [
      {
        name = "nix";
        root = "${home}/nixos-config";
      }
      {
        name = "muster";
        root = "${home}/repos";
      }
      {
        name = "plans";
        root = "${home}/repos";
      }
      {
        name = "ansible";
        root = "${home}/repos";
      }
      {
        name = "dashboard";
        root = "${home}/repos";
      }
      {
        name = "mix";
        root = home;
      }
    ];
  };
in {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [pkgs.smug];

    xdg.configFile."smug/daily.yml".source =
      (pkgs.formats.yaml {}).generate "smug-daily.yml" daily;
  };
}
