# This overlay takes an extra argument 'small' which is the 
# full nixos-25.11-small package set passed from flake.nix
small: final: prev: {
  small = small; # Expose the full small set
}
