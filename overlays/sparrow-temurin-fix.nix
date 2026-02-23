final: prev: {
  sparrow = final.callPackage (
    {
      stdenv,
      stdenvNoCC,
      lib,
      makeWrapper,
      fetchurl,
      makeDesktopItem,
      copyDesktopItems,
      autoPatchelfHook,
      temurin-bin-25, 
      gtk3,
      gsettings-desktop-schemas,
      writeScript,
      bash,
      tor,
      zlib,
      imagemagick,
      gzip,
      libusb1,
      pcsclite,
      udevCheckHook,
      glib,
      cairo,
      pango,
      xorg,
      libglvnd,
    }:

    let
      pname = "sparrow";
      version = "2.3.1";
      openjdk = temurin-bin-25;

      sparrowArch =
        {
          x86_64-linux = "x86_64";
          aarch64-linux = "aarch64";
        }
        ."${stdenvNoCC.hostPlatform.system}";

      src = fetchurl {
        url = "https://github.com/sparrowwallet/${pname}/releases/download/${version}/sparrowwallet-${version}-${sparrowArch}.tar.gz";
        sha256 =
          {
            x86_64-linux = "0hjjq4bamgfwfwl4rrxvrblhl7z9pw5bi245ncbd5gv3pi4a7h81";
            aarch64-linux = "04h3pampla6mhybdky5ihzjgi07in8rrhiz44n2n35c3n68mzdg5";
          }
          ."${stdenvNoCC.hostPlatform.system}";
      };

      launcher = writeScript "sparrow" ''
        #! ${bash}/bin/bash
        params=(
          -Dsun.security.smartcardio.library=${pcsclite.lib}/lib/libpcsclite.so.1
          -Dglass.gtk.uiScale=1.0 
          -Dsun.java2d.uiScale=1.0
          --module-path @out@/lib:@jdkModules@/modules
          --add-opens=javafx.graphics/com.sun.javafx.css=org.controlsfx.controls
          --add-opens=javafx.graphics/javafx.scene=org.controlsfx.controls
          --add-opens=javafx.controls/com.sun.javafx.scene.control.behavior=org.controlsfx.controls
          --add-opens=javafx.controls/com.sun.javafx.scene.control.inputmap=org.controlsfx.controls
          --add-opens=javafx.graphics/com.sun.javafx.scene.traversal=org.controlsfx.controls
          --add-opens=javafx.base/com.sun.javafx.event=org.controlsfx.controls
          --add-opens=javafx.controls/javafx.scene.control.cell=com.sparrowwallet.sparrow
          --add-opens=org.controlsfx.controls/impl.org.controlsfx.skin=com.sparrowwallet.sparrow
          --add-opens=org.controlsfx.controls/impl.org.controlsfx.skin=javafx.fxml
          --add-opens=javafx.graphics/com.sun.javafx.tk=centerdevice.nsmenufx
          --add-opens=javafx.graphics/com.sun.javafx.tk.quantum=centerdevice.nsmenufx
          --add-opens=javafx.graphics/com.sun.glass.ui=centerdevice.nsmenufx
          --add-opens=javafx.controls/com.sun.javafx.scene.control=centerdevice.nsmenufx
          --add-opens=javafx.graphics/com.sun.javafx.menu=centerdevice.nsmenufx
          --add-opens=javafx.graphics/com.sun.glass.ui=com.sparrowwallet.sparrow
          --add-opens=javafx.graphics/javafx.scene.input=com.sparrowwallet.sparrow
          --add-opens=javafx.graphics/com.sun.javafx.application=com.sparrowwallet.sparrow
          --add-opens=java.base/java.net=com.sparrowwallet.sparrow
          --add-opens=java.base/java.io=com.google.gson
          --add-opens=java.smartcardio/sun.security.smartcardio=com.sparrowwallet.sparrow
          --add-reads=com.sparrowwallet.merged.module=java.desktop
          --add-reads=com.sparrowwallet.merged.module=java.sql
          --add-reads=com.sparrowwallet.merged.module=com.sparrowwallet.sparrow
          --add-reads=com.sparrowwallet.merged.module=ch.qos.logback.classic
          --add-reads=com.sparrowwallet.merged.module=org.slf4j
          --add-reads=com.sparrowwallet.merged.module=com.fasterxml.jackson.databind
          --add-reads=com.sparrowwallet.merged.module=com.fasterxml.jackson.annotation
          --add-reads=com.sparrowwallet.merged.module=com.fasterxml.jackson.core
          --add-reads=com.sparrowwallet.merged.module=co.nstant.in.cbor
          --add-reads=kotlin.stdlib=kotlinx.coroutines.core
          -m com.sparrowwallet.sparrow
        )

        XDG_DATA_DIRS=${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}:$XDG_DATA_DIRS ${openjdk}/bin/java ''${params[@]} $@
      '';

      torWrapper = writeScript "tor-wrapper" ''
        #! ${bash}/bin/bash
        exec ${tor}/bin/tor "$@"
      '';

      jdk-modules = stdenvNoCC.mkDerivation {
        name = "jdk-modules";
        nativeBuildInputs = [ openjdk ];
        dontUnpack = true;
        buildPhase = ''
          mkdir modules
          pushd modules
          jimage extract ${openjdk}/lib/modules
          ls | xargs -d " " -- echo > ../manifest.txt
          popd
        '';
        installPhase = ''
          mkdir -p $out
          cp manifest.txt $out/
          cp -r modules/ $out/
        '';
      };

      sparrow-modules = stdenvNoCC.mkDerivation {
        pname = "sparrow-modules";
        inherit version src;
        nativeBuildInputs = [
          makeWrapper gzip openjdk autoPatchelfHook
          (lib.getLib stdenv.cc.cc) zlib libusb1 gtk3 glib cairo pango
          xorg.libXxf86vm xorg.libXtst libglvnd xorg.libX11
        ];

        buildPhase = ''
          mkdir modules
          pushd modules
          jimage extract ../lib/runtime/lib/modules
          cat ${jdk-modules}/manifest.txt | xargs -I {} -- rm -fR {}

          # --- DELETE NON-LINUX NATIVE LIBS (Fixes auto-patchelf errors) ---
          # JNA Cleanup
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/freebsd-x86-64
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/freebsd-x86
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/linux-arm
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/linux-armel
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/linux-mips64el
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/linux-ppc
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/linux-ppc64le
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/linux-s390x
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/linux-x86
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/linux-loongarch64
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/openbsd-x86-64
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/openbsd-x86
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/dragonflybsd-x86-64
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/sunos-sparc
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/sunos-sparcv9
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/sunos-x86-64
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/sunos-x86
          rm -fR com.sparrowwallet.merged.module/com/sun/jna/aix-ppc64

          # Webcam Cleanup
          rm -fR com.github.sarxos.webcam.capture/com/github/sarxos/webcam/ds/buildin/lib/linux_armel
          rm -fR com.github.sarxos.webcam.capture/com/github/sarxos/webcam/ds/buildin/lib/linux_armhf
          rm -fR com.github.sarxos.webcam.capture/com/github/sarxos/webcam/ds/buildin/lib/linux_x86
          rm -fR openpnp.capture.java/darwin-aarch64
          rm -fR openpnp.capture.java/darwin-x86-64
          rm -fR openpnp.capture.java/win32-x86-64

          # BridJ Cleanup
          rm -fR com.nativelibs4java.bridj/org/bridj/lib/linux_arm32_armel
          rm -fR com.nativelibs4java.bridj/org/bridj/lib/linux_armel
          rm -fR com.nativelibs4java.bridj/org/bridj/lib/linux_armhf
          rm -fR com.nativelibs4java.bridj/org/bridj/lib/linux_x86
          rm -fR com.nativelibs4java.bridj/org/bridj/lib/sunos_x64
          rm -fR com.nativelibs4java.bridj/org/bridj/lib/sunos_x86

          # Serial Port Cleanup
          rm -fR com.fazecast.jSerialComm/Android
          rm -fR com.fazecast.jSerialComm/Solaris
          rm -fR com.fazecast.jSerialComm/FreeBSD
          rm -fR com.fazecast.jSerialComm/OpenBSD

          # Lark / USB4Java Cleanup
          rm -fR org.usb4java/org/usb4java/linux-x86
          rm -fR org.usb4java/org/usb4java/linux-arm
          rm -fR org.usb4java/org/usb4java/freebsd-x86-64

          ls | xargs -d " " -- echo > ../manifest.txt
          find . | grep "\.so$" | xargs -- chmod ugo+x
          popd
          gzip -c ${torWrapper}  > tor.gz
          cp tor.gz modules/io.matthewnelson.kmp.tor.resource.exec.tor/io/matthewnelson/kmp/tor/resource/exec/tor/native/linux-libc/${sparrowArch}/tor.gz
        '';

        installPhase = ''
          mkdir -p $out
          cp manifest.txt $out/
          cp -r modules/ $out/
        '';
      };
    in
    stdenvNoCC.mkDerivation rec {
      inherit version src;
      pname = "sparrow";
      nativeBuildInputs = [ makeWrapper copyDesktopItems udevCheckHook ];

      desktopItems = [
        (makeDesktopItem {
          name = "sparrow-desktop";
          exec = "sparrow-desktop";
          icon = "sparrow-desktop";
          desktopName = "Sparrow Bitcoin Wallet";
          genericName = "Bitcoin Wallet";
          categories = [ "Finance" "Network" ];
          mimeTypes = [ "application/psbt" "application/bitcoin-transaction" "x-scheme-handler/bitcoin" "x-scheme-handler/auth47" "x-scheme-handler/lightning" ];
          startupWMClass = "Sparrow";
        })
      ];

      sparrow-icons = stdenvNoCC.mkDerivation {
        inherit version src;
        pname = "sparrow-icons";
        nativeBuildInputs = [ imagemagick ];
        installPhase = ''
          for n in 16 24 32 48 64 96 128 256; do
            size=$n"x"$n
            mkdir -p $out/hicolor/$size/apps
            convert lib/Sparrow.png -resize $size $out/hicolor/$size/apps/sparrow-desktop.png
          done;
        '';
      };

      installPhase = ''
        mkdir -p $out/bin $out
        ln -s ${sparrow-modules}/modules $out/lib
        install -D -m 777 ${launcher} $out/bin/sparrow-desktop
        substituteAllInPlace $out/bin/sparrow-desktop
        substituteInPlace $out/bin/sparrow-desktop --subst-var-by jdkModules ${jdk-modules}
        mkdir -p $out/share/icons
        ln -s ${sparrow-icons}/hicolor $out/share/icons
        mkdir -p $out/etc/udev/
        ln -s ${sparrow-modules}/modules/com.sparrowwallet.lark/udev $out/etc/udev/rules.d
      '';

      meta = with lib; {
        description = "Modern Bitcoin wallet emphasizing transparency and usability";
        homepage = "https://sparrowwallet.com";
        license = licenses.asl20;
        platforms = [ "x86_64-linux" "aarch64-linux" ];
        mainProgram = "sparrow-desktop";
      };
    }
  ) {
    temurin-bin-25 = final.temurin-bin-25;
  };
}