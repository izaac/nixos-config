{
  python3Packages,
  fetchFromGitHub,
  qt6,
  copyDesktopItems,
  makeDesktopItem,
  gsettings-desktop-schemas,
  glib,
  wrapGAppsHook3,
}:
python3Packages.buildPythonApplication {
  pname = "FlashGBX";
  version = "master";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "lesserkuma";
    repo = "FlashGBX";
    rev = "master";
    hash = "sha256-rxeIGs8Afm2VSVMRd4a84ujkuiV56Q5jwj+5zXtNitk=";
  };

  nativeBuildInputs = [
    python3Packages.setuptools
    qt6.wrapQtAppsHook
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs = [
    gsettings-desktop-schemas
    glib
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
  dontWrapGApps = true;

  postFixup = ''
    wrapQtApp $out/bin/flashgbx "''${gappsWrapperArgs[@]}"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "FlashGBX";
      exec = "flashgbx";
      icon = "media-flash";
      desktopName = "FlashGBX";
      genericName = "GameBoy Flasher";
      categories = ["Game"];
    })
  ];

  doCheck = false;
}
