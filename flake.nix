{
  description = "Nix flake for CECC Linux prebuilt release binaries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev: {
        excalibur-control-center = final.callPackage ./nix/package.nix { };
      };
    in
    flake-utils.lib.eachSystem [
      "x86_64-linux"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          default = pkgs.excalibur-control-center;
          excalibur-control-center = pkgs.excalibur-control-center;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.excalibur-control-center}/bin/excalibur-control-center-gui";
          };
          gui = {
            type = "app";
            program = "${pkgs.excalibur-control-center}/bin/excalibur-control-center-gui";
          };
          cli = {
            type = "app";
            program = "${pkgs.excalibur-control-center}/bin/excalibur-control-center-cli";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
          ];
        };
      }) // {
        overlays.default = overlay;
        nixosModules.default = import ./nix/module.nix;
      };
}
