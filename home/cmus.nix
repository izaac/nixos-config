{ pkgs, ... }:

{
  programs.cmus = {
    enable = true;
    extraConfig = ''
      # Catppuccin Mauve Theme
      set color_cmdline_bg=default
      set color_cmdline_fg=default
      set color_error=160
      set color_info=147
      set color_separator=243
      set color_statusline_bg=0
      set color_statusline_fg=147
      set color_titleline_bg=0
      set color_titleline_fg=183
      set color_win_bg=default
      set color_win_cur=183
      set color_win_cur_sel_bg=183
      set color_win_cur_sel_fg=0
      set color_win_dir=147
      set color_win_fg=default
      set color_win_inactive_cur_sel_bg=243
      set color_win_inactive_cur_sel_fg=0
      set color_win_inactive_sel_bg=0
      set color_win_inactive_sel_fg=243
      set color_win_sel_bg=147
      set color_win_sel_fg=0
      set color_win_title_bg=0
      set color_win_title_fg=183
    '';
  };
}
