# Pins dwarfs to a pre-built universal binary.
# Check for updates: https://github.com/mhx/dwarfs/releases
# To update: bump version + run `nix build` to get new hashes from errors.
final: _prev: {
  dwarfs = final.stdenvNoCC.mkDerivation rec {
    pname = "dwarfs";
    version = "0.15.1";

    src = let
      inherit (final.stdenvNoCC.hostPlatform) system;
      hashes = {
        "x86_64-linux" = "191gi4936dm4nf613pr6a0w452mrbdzn453s76b2s9x27ra0qxb9";
        "aarch64-linux" = "1jjc4a6da7yysdfar39nwsa2x70bg3wb20vmndddhik488911z9n";
      };
      arch =
        {
          "x86_64-linux" = "x86_64";
          "aarch64-linux" = "aarch64";
        }.${
          system
        };
    in
      final.fetchurl {
        url = "https://github.com/mhx/dwarfs/releases/download/v${version}/dwarfs-universal-${version}-Linux-${arch}";
        sha256 = hashes.${system};
      };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/dwarfs
      chmod +x $out/bin/dwarfs
      ln -s dwarfs $out/bin/mkdwarfs
      ln -s dwarfs $out/bin/dwarfsck
      ln -s dwarfs $out/bin/dwarfsextract
    '';

    meta = with final.lib; {
      description = "Fast high compression read-only file system";
      homepage = "https://github.com/mhx/dwarfs";
      license = licenses.gpl3Plus;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "dwarfs";
    };
  };
}
