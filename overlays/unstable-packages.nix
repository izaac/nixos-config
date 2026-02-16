# This overlay takes an extra argument 'unstable' which is the
# full nixos-unstable package set passed from flake.nix
# Purpose: Selectively pull in specific applications from unstable that offer
# better features/performance compared to stable versions
unstable: final: prev: {
  unstable = unstable; # Expose the full unstable set for reference
  
  # Development tools - newer versions with better features
  vscode = unstable.vscode;           # Latest features and extensions
  
  # Gaming tools - better compatibility with latest games
  heroic = unstable.heroic;           # Updated game compatibility
  lutris = unstable.lutris;           # Better game installer support
  protonplus = unstable.protonplus;   # GTK Proton manager
  protonup-rs = unstable.protonup-rs; # CLI Proton manager
  bottles = unstable.bottles;         # Updated Windows app compatibility
  
  # Communication - latest features and security updates
  telegram-desktop = unstable.telegram-desktop; # Newest features and fixes
  
  # System utilities - better hardware support or features
  goverlay = unstable.goverlay;                 # GPU monitoring overlay
  whosthere = unstable.whosthere;               # TUI network discovery tool
}
