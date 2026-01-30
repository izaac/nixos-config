# This overlay takes an extra argument 'unstable' which is the 
# full nixos-unstable package set passed from flake.nix
unstable: final: prev: {
  vscode = unstable.vscode;
  heroic = unstable.heroic;
  lutris = unstable.lutris;
  telegram-desktop = unstable.telegram-desktop;
  protonup-qt = unstable.protonup-qt;
  mission-center = unstable.mission-center;
  bottles = unstable.bottles;
}
