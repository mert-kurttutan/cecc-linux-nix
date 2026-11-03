{
  lib,
  stdenv,
  autoPatchelfHook,
  copyDesktopItems,
  fetchzip,
  fetchurl,
  fontconfig,
  libxkbcommon,
  makeDesktopItem,
  makeWrapper,
  wayland,
}:

let
  version = "0.1.38";
  sourceSha256 = "1bq7mbakvjqqhbp9x4mk35ajpy65d5xds7x9zwwzra9llqblbxpn";

  releases = {
    x86_64-linux = {
      gui = {
        asset = "excalibur-control-center-gui";
        sha256 = "09rb394wzj3rspz0441wvlxnhw0crrm7yx0fcy3dykg515qq5h3l";
      };
      cli = {
        asset = "excalibur-control-center-cli";
        sha256 = "1dn1xfrdhqfg2gsx3kl0gkdhfhdmglpkr299dj380b6dypidr89n";
      };
    };
  };

  release =
    releases.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  guiSrc = fetchurl {
    url = "https://github.com/mert-kurttutan/cecc-linux/releases/download/v${version}/${release.gui.asset}";
    inherit (release.gui) sha256;
  };

  cliSrc = fetchurl {
    url = "https://github.com/mert-kurttutan/cecc-linux/releases/download/v${version}/${release.cli.asset}";
    inherit (release.cli) sha256;
  };

  ceccSource = fetchzip {
    url = "https://github.com/mert-kurttutan/cecc-linux/archive/refs/tags/v${version}.tar.gz";
    sha256 = sourceSha256;
  };

  desktopItem = makeDesktopItem {
    name = "excalibur-control-center";
    desktopName = "Excalibur Control Center";
    genericName = "Hardware Control Center";
    comment = "Control Casper Excalibur laptop performance, GPU mode, and keyboard lighting";
    exec = "excalibur-control-center-gui";
    icon = "excalibur-control-center";
    terminal = false;
    categories = [
      "Settings"
      "HardwareSettings"
      "System"
    ];
    keywords = [
      "excalibur"
      "casper"
      "keyboard"
      "rgb"
      "fan"
      "gpu"
      "performance"
    ];
    startupNotify = false;
  };

  runtimeLibs = [
    fontconfig
    libxkbcommon
    stdenv.cc.cc.lib
    wayland
  ];
in
stdenv.mkDerivation {
  pname = "excalibur-control-center";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = runtimeLibs;

  desktopItems = [
    desktopItem
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${guiSrc} "$out/bin/.excalibur-control-center-gui-unwrapped"
    install -Dm755 ${cliSrc} "$out/bin/excalibur-control-center-cli"

    makeWrapper "$out/bin/.excalibur-control-center-gui-unwrapped" \
      "$out/bin/excalibur-control-center-gui" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib

    if [ -r "${ceccSource}/packaging/excalibur-control-center.svg" ]; then
      install -Dm644 "${ceccSource}/packaging/excalibur-control-center.svg" \
        "$out/share/icons/hicolor/scalable/apps/excalibur-control-center.svg"
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "Control center for Casper Excalibur laptops";
    homepage = "https://github.com/mert-kurttutan/cecc-linux";
    license = licenses.gpl2Plus;
    platforms = builtins.attrNames releases;
    mainProgram = "excalibur-control-center-gui";
  };
}
