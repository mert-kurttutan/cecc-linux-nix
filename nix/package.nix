{
  lib,
  stdenv,
  autoPatchelfHook,
  fetchurl,
  fontconfig,
  libxkbcommon,
  makeWrapper,
  wayland,
}:

let
  version = "0.1.19";

  releases = {
    x86_64-linux = {
      gui = {
        asset = "excalibur-control-center-gui";
        sha256 = "08rdb3qz8wbr1lxq4ca2xw3f2pmrm06b4wpnmj9655c131amc4r8";
      };
      cli = {
        asset = "excalibur-control-center-cli";
        sha256 = "0rml5p5c7azzmiqhgmavp2ygvkg9m5s80blz86y0i7rbl996rvsa";
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
    makeWrapper
  ];

  buildInputs = runtimeLibs;

  installPhase = ''
    runHook preInstall

    install -Dm755 ${guiSrc} "$out/bin/.excalibur-control-center-gui-unwrapped"
    install -Dm755 ${cliSrc} "$out/bin/excalibur-control-center-cli"

    makeWrapper "$out/bin/.excalibur-control-center-gui-unwrapped" \
      "$out/bin/excalibur-control-center-gui" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}

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
