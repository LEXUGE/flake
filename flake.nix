{
  description = "Deterministic Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";

    # Programmable DNS component used in our systems
    dcompass.url = "github:compassd/dcompass";
  };

  outputs = { self, nixpkgs, utils, dcompass, ... }@inputs: with utils.lib; let
    lib = nixpkgs.lib;

    mkSystem = { name, extraMods ? [ ], extraOverlays ? [ ], system }: (lib.nixosSystem {
      inherit system;
      modules = [
        ./cfgs/${name}
        { nixpkgs.overlays = [ self.overlays.default ] ++ extraOverlays; }
      ] ++ extraMods;
    });
  in
  rec {
    # Use the default overlay to export all packages under ./pkgs
    overlays.default = final: prev:
      (import ./pkgs {
        inherit (prev) lib;
        pkgs = prev;
      });

    # Export modules under ./modules as NixOS modules
    nixosModules = (import ./modules { inherit lib; });

    # Export system cfgs
    nixosConfigurations.x1c7 = mkSystem {
      name = "x1c7";
      extraMods = [
        nixosModules.clash
        nixosModules.base
        nixosModules.gnome-desktop
        nixosModules.dcompass
        ./cfgs/x1c7
      ];
      extraOverlays = [ dcompass.overlays.default ];
      system = system.x86_64-linux;
    };

    nixosConfigurations.x1c7-img = mkSystem {
      name = "x1c7-img";
      extraMods = [
        nixosModules.clash
        nixosModules.base
        nixosModules.gnome-desktop
        nixosModules.dcompass
        ./cfgs/x1c7-img
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
      ];
      extraOverlays = [ dcompass.overlays.default ];
      system = system.x86_64-linux;
    };

    # ISO image entry point
    x1c7-img = nixosConfigurations.x1c7-img.config.system.build.isoImage;
  } // eachSystem [ system.x86_64-linux ] (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in
    {
      # Other than overlay, we have packages independently declared in flake.
      packages = (import ./pkgs { inherit lib pkgs; });

      apps = rec {
        fmt = utils.lib.mkApp {
          drv = with import nixpkgs { inherit system; };
            pkgs.writeShellScriptBin "flake-fmt" ''
              export PATH=${
                pkgs.lib.strings.makeBinPath [
                  findutils
                  nixpkgs-fmt
                  shfmt
                  shellcheck
                ]
              }
              find . -type f -name '*.sh' -exec shellcheck {} +
              find . -type f -name '*.sh' -exec shfmt -w {} +
              find . -type f -name '*.nix' -exec nixpkgs-fmt {} +
            '';
        };
        default = fmt;
      };
    });
}
