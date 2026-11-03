{
  lib,
  stdenv,
  kernel,
  src,
}:

stdenv.mkDerivation {
  pname = "casper-wmi";
  version = "0.1";

  inherit src;

  # This driver is C-only. Nixpkgs adds Rust tools to the generic kernel
  # module dependencies when the kernel enables Rust, but this module does
  # not invoke bindgen.
  nativeBuildInputs = builtins.filter
    (dependency: lib.getName dependency != "rust-bindgen-unwrapped")
    kernel.moduleBuildDependencies;

  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 casper-wmi.ko "$out/lib/modules/${kernel.modDirVersion}/extra/casper-wmi.ko"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Casper Excalibur WMI driver";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
