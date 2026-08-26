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
  version = "0.1.32";
  sourceSha256 = "0n0knndlscmmq6qg817l3gv616wiw9ra5y58cdqr3481izs0a9h2";

  releases = {
    x86_64-linux = {
      gui = {
        asset = "excalibur-control-center-gui";
        sha256 = "0ma6qpf3520zdzlm4djw5h4lqf984vhmg9d9lqk0dw78g6dy23al";
      };
      cli = {
        asset = "excalibur-control-center-cli";
        sha256 = "1rk10cxd1kaf0gdaq1m1d0zj5cfcdg73ywva2lw6hww4s3q1v1vq";
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
    startupNotify = true;
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
