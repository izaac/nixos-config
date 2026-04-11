_: {
  catppuccin.zellij.enable = true;

  programs.zellij = {
    enable = true;
    settings = {
      pane_frames = false;
      mouse_mode = true;
      copy_on_select = true;
      session_serialization = true;
      auto_layout = true;
      show_startup_tips = false;
      default_layout = "compact";
    };

    # Raw KDL keybindings — bypasses Nix-to-KDL serializer for reliability.
    # Mimics tmux: Ctrl-a prefix, vim nav, | / v splits, Ctrl-a toggle last tab.
    extraConfig = ''
      keybinds {
        unbind "Ctrl b"
        shared_except "locked" {
          bind "Ctrl a" { SwitchToMode "Tmux"; }
        }
        tmux {
          bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
          bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
          bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
          bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
          bind "\\" { NewPane "Right"; SwitchToMode "Normal"; }
          bind "v" { NewPane "Down"; SwitchToMode "Normal"; }
          bind "c" { NewTab; SwitchToMode "Normal"; }
          bind "n" { GoToNextTab; SwitchToMode "Normal"; }
          bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
          bind "&" { CloseTab; SwitchToMode "Normal"; }
          bind "x" { CloseFocus; SwitchToMode "Normal"; }
          bind "Ctrl a" { ToggleTab; SwitchToMode "Normal"; }
          bind "a" { Write 1; SwitchToMode "Normal"; }
          bind "," { SwitchToMode "RenameTab"; }
          bind "$" { SwitchToMode "RenamePane"; }
          bind "d" { Detach; }
        }
      }
    '';
  };
}
