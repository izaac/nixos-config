{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  pname = "vcrunch";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pkgs.python3 ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp vcrunch.py $out/bin/vcrunch
    chmod +x $out/bin/vcrunch

    wrapProgram $out/bin/vcrunch \
      --prefix PATH : ${pkgs.lib.makeBinPath [ 
        pkgs.ffmpeg-full 
        pkgs.pv 
        pkgs.rsync 
        pkgs.libnotify 
      ]}
  '';

  meta = {
    description = "Consolidated video re-encoding tool suite";
    platforms = pkgs.lib.platforms.linux;
  };
}
