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
  version = "0.1.34";
  sourceSha256 = "1vag4n40mk06krkd0rhggzz62dfmw6lmazhc91lzm90cs0pdpgw4";

  releases = {
    x86_64-linux = {
      gui = {
        asset = "excalibur-control-center-gui";
        sha256 = "1rr17zz88z9cn9hvwv9y23yw7r8x4b4nk751p9lr31i47bm8hqzv";
      };
      cli = {
        asset = "excalibur-control-center-cli";
        sha256 = "1glr7r5zmiphjr800c1kapmapah6y09v9hx9zbxjcb13nqcjky2b";
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
