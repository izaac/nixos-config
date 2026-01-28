{ lib
, python3Packages
, fetchFromGitHub
, qt6
, copyDesktopItems
, makeDesktopItem
}:

python3Packages.buildPythonApplication {
  pname = "FlashGBX";
  version = "master";
  pyproject = true;
  
  src = fetchFromGitHub {
    owner = "lesserkuma";
    repo = "FlashGBX";
    rev = "master";
    sha256 = "0fwp6idyn9203m3nh9yk7zhbcvmjh1fkxkb3f1gbs961w1zsqr5p";
  };

  nativeBuildInputs = [ 
    python3Packages.setuptools
    qt6.wrapQtAppsHook
    copyDesktopItems
  ];

  propagatedBuildInputs = with python3Packages; [
    pyside6
    pyserial
    pillow
    requests
    python-dateutil
    packaging
    qt6.qtwayland
    qt6.qtsvg
    qt6.qtbase
  ];

  dontWrapQtApps = true;

  postFixup = ''
    wrapQtApp $out/bin/flashgbx
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "FlashGBX";
      exec = "flashgbx";
      icon = "FlashGBX";
      desktopName = "FlashGBX";
      genericName = "GameBoy Flasher";
      categories = [ "Game" ];
    })
  ];

  doCheck = false;
}
