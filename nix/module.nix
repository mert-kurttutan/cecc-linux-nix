{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.excalibur-control-center;

  version = "0.1.32";
  ceccSource = pkgs.fetchzip {
    url = "https://github.com/mert-kurttutan/cecc-linux/archive/refs/tags/v${version}.tar.gz";
    sha256 = "0n0knndlscmmq6qg817l3gv616wiw9ra5y58cdqr3481izs0a9h2";
  };

  casperWmi = config.boot.kernelPackages.callPackage ./casper-wmi.nix {
    src = ceccSource + "/casper-wmi";
  };

  excaliburControlCenter = pkgs.callPackage ./package.nix { };

  applySysfsPermissions = pkgs.writeShellScript "excalibur-apply-sysfs-permissions" ''
    exec ${pkgs.bash}/bin/bash ${ceccSource}/scripts/driver-bash/apply-sysfs-permissions.sh "$@"
  '';
in
{
  options.services.excalibur-control-center = {
    enable = lib.mkEnableOption "Excalibur Control Center";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "kmert" ];
      description = "Users to add to the excalibur hardware-access group.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "excalibur";
      description = "Group allowed to access the CECC sysfs controls.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      excaliburControlCenter
    ];

    boot.extraModulePackages = [
      casperWmi
    ];

    boot.kernelModules = [
      "casper-wmi"
    ];

    users.groups.${cfg.group} = { };

    users.users = lib.genAttrs cfg.users (user: {
      extraGroups = [ cfg.group ];
    });

    services.udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="leds", KERNEL=="casper:rgb:*", RUN+="${applySysfsPermissions} leds %k"
      ACTION=="add|change", SUBSYSTEM=="module", KERNEL=="casper_wmi", RUN+="${applySysfsPermissions} module"
      ACTION=="add|change", SUBSYSTEM=="module", KERNEL=="casper_wmi", RUN+="${applySysfsPermissions} platform"
    '';
  };
}
