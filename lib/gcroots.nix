# GC root target for the pinned flake input graph.
#
# Eval-time-only sources (e.g. stylix's base16-schemes) are not referenced by
# any built system, so the garbage collector can delete them and break
# `nix flake check` with "path ... is not valid". Building this linkFarm with
# --out-link keeps every input in flake.lock alive until the root is refreshed
# (see the `gcroots` just recipe, wired into `just up`).
{
  inputs,
  pkgs,
}: let
  inherit (pkgs) lib;

  # Walk the input graph (diamonds included, flakes forbid cycles) and emit
  # one linkFarm entry per input source.
  collect = prefix: input:
    [
      {
        name = prefix;
        path = input.outPath;
      }
    ]
    ++ lib.concatLists (
      lib.mapAttrsToList (name: sub: collect "${prefix}-${name}" sub) (input.inputs or {})
    );
in
  # self re-exports every input under self.inputs, so root its source but
  # skip the recursion to keep the linkFarm free of duplicates.
  pkgs.linkFarm "flake-inputs" (
    lib.concatLists (
      lib.mapAttrsToList (
        name: input:
          if name == "self"
          then [
            {
              inherit name;
              path = input.outPath;
            }
          ]
          else collect name input
      )
      inputs
    )
  )
