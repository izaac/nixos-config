{ pkgs, ... }:

{
  # QA Check: We need these binaries available for the Vim plugins to work
  home.packages = with pkgs; [
    nodePackages.bash-language-server
    shellcheck
  ];

  programs.vim = {
    enable = true;
    
    # The "Plug" section replaced by Nix packages
    plugins = with pkgs.vimPlugins; [
      vim-sensible
      vim-shellcheck
      vim-gitgutter
      vim-javascript
      typescript-vim
      vim-jsx-pretty
      vim-graphql
      coc-nvim
      sonokai
      vim-fugitive
      fzf-vim
    ];

    # Basic settings map directly to Nix options
    settings = {
      number = true;
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
    };

    # The rest of your specific logic goes here
    extraConfig = ''
      " --- Bash Language Server Setup ---
      if executable('bash-language-server')
        au User lsp_setup call lsp#register_server({
          \ 'name': 'bash-language-server',
          \ 'cmd': {server_info->['bash-language-server', 'start']},
          \ 'allowlist': ['sh', 'bash'],
          \ })
      endif

      " --- Bash Goodies ---
      nnoremap ex :!chmod +x % && source %
      nnoremap sh ggO#!/bin/bash<ESC>o<ESC>
      nnoremap @c I <ESC>A #<ESC>yyPlvt#r-yyjp

      " --- FZF ---
      nnoremap <C-p> :Files!<CR>
      nnoremap <C-0> :Files<CR>

      " --- Window Movement ---
      map <C-j> <C-W>j
      map <C-k> <C-W>k
      map <C-h> <C-W>h
      map <C-l> <C-W>l
      nnoremap <Leader>w <C-w>

      " --- Buffer Switching ---
      map <F5> :ls<CR>:e #

      " --- CoC Configuration ---
      let g:coc_global_extensions = ['coc-tsserver']
      
      " Enter accepts completion
      inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

      " --- Theme: Sonokai (Atlantis) ---
      if has('termguicolors')
        set termguicolors
      endif
      let g:sonokai_style = 'atlantis'
      let g:sonokai_better_performance = 1
      colorscheme sonokai
    '';
  };
}
