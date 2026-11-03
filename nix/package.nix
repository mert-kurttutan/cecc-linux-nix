{
  lib,
  stdenvNoCC,
  copyDesktopItems,
  fetchzip,
  fetchurl,
  makeDesktopItem,
}:

let
  version = "0.1.40";
  sourceSha256 = "0xzl5qf5998hq4viyv8hd8bhaskhzmrc1zx5626scxcraxalh2bs";

  releases = {
    x86_64-linux = {
      gui = {
        asset = "excalibur-control-center-gui";
        sha256 = "14drv3lyllbfisir7s9x5lgjc1nbkw0p8gm519j5mr11ylg0a30v";
      };
      cli = {
        asset = "excalibur-control-center-cli";
        sha256 = "1mxddwivy17khydzz2rxfbfq8vih2jmp2iy3r7zx3dfbr13fh1j9";
      };
    };
  };

  release =
    releases.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

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
in
stdenvNoCC.mkDerivation {
  pname = "excalibur-control-center";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [
    copyDesktopItems
  ];

  desktopItems = [
    desktopItem
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${guiSrc} "$out/bin/excalibur-control-center-gui"
    install -Dm755 ${cliSrc} "$out/bin/excalibur-control-center-cli"

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
