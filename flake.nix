{
  description = "Deterministic Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";

    # Programmable DNS component used in our systems
    # Don't follow as it may invalidate the cache
    dcompass.url = "github:compassd/dcompass";

    # My emacs config
    ash-emacs.url = "github:LEXUGE/emacs.d";
    ash-emacs.inputs.nixos.follows = "nixpkgs";

    # Tool for NixOS on tmpfs
    impermanence.url = "github:nix-community/impermanence";

    # Home manager
    # Broken due to https://github.com/nix-community/home-manager/pull/3405
    # home-manager.url = "github:nix-community/home-manager";
    home-manager.url = "github:NickCao/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Secrets management
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, utils, dcompass, impermanence, ash-emacs, home-manager, agenix }: with utils.lib; let
    lib = nixpkgs.lib;

    mkSystem = { name, extraMods ? [ ], extraOverlays ? [ ], system }: (lib.nixosSystem {
      inherit system;
      modules = [
        ./cfgs/${name}
        {
          nixpkgs.overlays = [ self.overlays.default ] ++ extraOverlays;
          nix.settings = {
            substituters = [ "https://dcompass.cachix.org" "https://nix-community.cachix.org" ];
            trusted-public-keys = [ dcompass.publicKey "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
          };
        }
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
        nixosModules.home
        nixosModules.gnome-desktop
        nixosModules.dcompass
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
        agenix.nixosModules.age
        ./cfgs/x1c7
      ];
      extraOverlays = [ dcompass.overlays.default ash-emacs.overlays.default ];
      system = system.x86_64-linux;
    };

    nixosConfigurations.x1c7-img = mkSystem {
      name = "x1c7-img";
      extraMods = [
        nixosModules.clash
        nixosModules.home
        nixosModules.base
        nixosModules.gnome-desktop
        nixosModules.dcompass
        home-manager.nixosModules.home-manager
        agenix.nixosModules.age
        ./cfgs/x1c7-img
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
      ];
      extraOverlays = [ dcompass.overlays.default ash-emacs.overlays.default ];
      system = system.x86_64-linux;
    };

    # ISO image entry point
    x1c7-img = nixosConfigurations.x1c7-img.config.system.build.isoImage;
  } // eachSystem [ system.x86_64-linux ] (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in
    {
      # Other than overlay, we have packages independently declared in flake.
      packages = (import ./pkgs { inherit lib pkgs; });

      # devShell used to launch agenix env.
      devShells.default = with import nixpkgs { inherit system; };
        mkShell {
          nativeBuildInputs = [ openssl agenix.defaultPackage.${system} ];
        };

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
