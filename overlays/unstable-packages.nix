# This overlay is now a legacy container for specific version overrides
# It no longer pulls from the unstable branch to ensure maximum binary cache hits
final: prev: {
  # We can keep this empty or use it for specific manual overrides if needed.
  # For now, we let the system use standard stable versions from nixpkgs-25.11.
}
