{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;

    settings = {
      # 1. Global Layout
      add_newline = false;
      format = "$directory$git_branch$git_status$nodejs$python$rust$golang$container$character";
      right_format = "$cmd_duration";

      # 2. The Prompt Character
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
        vimcmd_symbol = "[N](bold blue)";
      };

      # 3. Directory (The path)
      directory = {
        style = "bold lavender";
        truncation_length = 3;
        truncation_symbol = "…/";
        read_only = " 🔒";
      };

      # 4. Git Integration
      git_branch = {
        symbol = " ";
        style = "bold mauve";
      };
      git_status = {
        style = "bold red";
        format = "[$all_status$ahead_behind]($style) ";
      };

      # 5. Distrobox / Container Indicator (CRITICAL for you)
      # This will show "📦 ubuntu-20.04" when you are inside a box.
      container = {
        disabled = false;
        format = "[$symbol $name]($style) ";
        symbol = "📦";
        style = "boldred";
      };

      # 6. Language Versions (Only show when relevant files exist)
      nodejs = {
        symbol = " ";
        style = "bold green";
        detect_files = [ "package.json" ".nvmrc" ];
      };
      python = {
        symbol = "🐍 ";
        style = "bold yellow";
        detect_files = [ "requirements.txt" "pyproject.toml" ];
      };
      rust = {
        symbol = "🦀 ";
        style = "bold red";
      };
      golang = {
        symbol = "🐹 ";
        style = "bold cyan";
      };

      # 7. Command Duration (Shows if a command took > 2s)
      cmd_duration = {
        min_time = 2000;
        style = "bold yellow";
        format = "[$duration]($style)";
      };
    };
  };
}
