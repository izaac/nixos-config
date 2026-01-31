{
  description = "Node.js development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      devShells = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs
              pnpm
              yarn
            ];

            shellHook = ''
              echo "Node.js dev environment activated."
              echo "Tools: node $(node --version), pnpm $(pnpm --version), yarn $(yarn --version)"
            '';
          };
        });
    };
}
