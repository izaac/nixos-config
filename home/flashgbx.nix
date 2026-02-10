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
    hash = "sha256-GQBLLUd30MAqlPWTeTPpxp4llzpttL65ih9P6NSA+5w=";
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
      icon = "media-flash";
      desktopName = "FlashGBX";
      genericName = "GameBoy Flasher";
      categories = [ "Game" ];
    })
  ];

  doCheck = false;
}
