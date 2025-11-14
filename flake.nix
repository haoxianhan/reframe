{
  description = "ReFrame remote desktop flake with package, devshell and overlay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        reframe = pkgs.callPackage ./nix/package.nix { };
      in
      {
        packages = {
          inherit reframe;
          default = reframe;
        };

        apps.default = {
          type = "app";
          program = "${reframe}/bin/reframe-server";
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ reframe ];
          packages = with pkgs; [
            clang
            gdb
            glib.dev
            libdrm
            libepoxy
            libvncserver
            libxkbcommon
            meson
            ninja
            pkg-config
            python3
            mesa-demos
            systemd
          ];
          shellHook = ''
            export G_MESSAGES_DEBUG=ReFrame
          '';
        };
      }) // {
        overlays.default = final: _: {
          reframe = final.callPackage ./nix/package.nix { };
        };

        nixosModules.default = import ./nix/reframe-module.nix;
      };
}
