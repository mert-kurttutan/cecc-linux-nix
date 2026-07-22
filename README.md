# cecc-linux-nix

Nix flake for installing CECC Linux prebuilt release binaries and the
`casper-wmi` driver on NixOS.

## Run

```bash
nix run github:mert-kurttutan/cecc-linux-nix#gui
nix run github:mert-kurttutan/cecc-linux-nix#cli
```

## NixOS

Add the flake input:

```nix
cecc-linux-nix.url = "github:mert-kurttutan/cecc-linux-nix";
```

Import the module:

```nix
imports = [
  inputs.cecc-linux-nix.nixosModules.default
];

services.excalibur-control-center = {
  enable = true;
  users = [ "kmert" ];
};
```

Rebuild and reboot so the kernel module and group membership are active:

```bash
sudo nixos-rebuild switch
```

## Package

The package currently targets `x86_64-linux` and fetches release assets from
`mert-kurttutan/cecc-linux`.
