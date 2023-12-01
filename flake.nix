{
  description = "Deterministic Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # We seem to have problem with mesa, let's pin it to 22.2
    # nixpkgs.url = "github:nixos/nixpkgs/6dccdc458512abce8d19f74195bb20fdb067df50";

    utils.url = "github:numtide/flake-utils";

    nvfetcher.url = "github:berberman/nvfetcher";
    nvfetcher.inputs.nixpkgs.follows = "nixpkgs";

    # Programmable DNS component used in our systems
    # Don't follow as it may invalidate the cache
    dcompass.url = "github:compassd/dcompass";
    dcompass.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative Disk Management
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Steam-deck experience on NixOS
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS";
    jovian.inputs.nixpkgs.follows = "nixpkgs";

    # My emacs config
    # ash-emacs.url = "/home/ash/Documents/git/emacs.d";
    ash-emacs.url = "github:LEXUGE/emacs.d";
    ash-emacs.inputs.nixos.follows = "nixpkgs";

    # SecureBoot Management
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    # Tool for NixOS on tmpfs
    impermanence.url = "github:nix-community/impermanence";

    # Home manager
    # Broken due to https://github.com/nix-community/home-manager/pull/3405
    home-manager.url = "github:nix-community/home-manager";
    # home-manager.url = "github:NickCao/home-manager";
    # home-manager.url = "github:LEXUGE/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Secrets management
    # agenix.url = "github:ryantm/agenix/d7fd31756e1c5f1281981c48efbb2e188024ba47";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # pre-commit hooks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, nvfetcher, dcompass, impermanence, ash-emacs, home-manager, agenix, disko, jovian, lanzaboote, pre-commit-hooks }@inputs: with utils.lib; let
    lib = nixpkgs.lib;

    mkSystem = { name, extraMods ? [ ], extraOverlays ? [ ], system }: (lib.nixosSystem {
      inherit system;
      modules = [
        ./cfgs/${name}
        {
          nixpkgs.overlays = [ self.overlays.default ] ++ extraOverlays;
          nix.settings = {
            substituters = [ "https://dcompass.cachix.org" "https://nix-community.cachix.org" "https://lexuge.cachix.org" ];
            trusted-public-keys = [ dcompass.publicKey "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" self.publicKey ];
          };
          nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
        }
      ] ++ extraMods;
      specialArgs = { inherit inputs; };
    });
  in
  rec {
    # Use the default overlay to export all packages under ./pkgs
    overlays = {
      # Patch mathematica to solve "libdbus not found" error.
      mathematica = (final: prev: {
        mathematica_13_3_1 = (prev.mathematica.overrideAttrs (_: prevAttrs: {
          wrapProgramFlags = prevAttrs.wrapProgramFlags ++ [ "--prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath [ prev.dbus.lib ]}" ];
        })).override {
          version = "13.3.1";
        };
      });

      default = final: prev:
        (import ./pkgs {
          inherit (prev) lib;
          pkgs = prev;
          overlay = true;
        });
    };

    # Export modules under ./modules as NixOS modules
    nixosModules = (import ./modules { inherit lib; });

    # Export system cfgs
    nixosConfigurations.x1c7 = mkSystem {
      name = "x1c7";
      extraMods = [
        nixosModules.clash
        nixosModules.base
        nixosModules.disko
        nixosModules.lanzaboote
        nixosModules.home
        nixosModules.gnome-desktop
        nixosModules.dcompass
        impermanence.nixosModules.impermanence
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        lanzaboote.nixosModules.lanzaboote
        agenix.nixosModules.age
      ];
      extraOverlays = [
        dcompass.overlays.default
        ash-emacs.overlays.default
        self.overlays.mathematica
      ];
      system = system.x86_64-linux;
    };

    diskoConfigurations = {
      deck = (import ./modules/disko/disk.nix { });
      x1c7 = (import ./modules/disko/disk.nix { });
    };

    nixosConfigurations.deck = mkSystem {
      name = "deck";
      extraMods = [
        nixosModules.clash
        nixosModules.base
        nixosModules.disko
        nixosModules.lanzaboote
        nixosModules.home
        nixosModules.gnome-desktop
        nixosModules.dcompass
        disko.nixosModules.disko
        nixosModules.steamdeck
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
        agenix.nixosModules.age
        lanzaboote.nixosModules.lanzaboote
        jovian.nixosModules.default
      ];
      extraOverlays = [
        dcompass.overlays.default
        ash-emacs.overlays.default
      ];
      system = system.x86_64-linux;
    };

    nixosConfigurations.img-x1c7 = mkSystem {
      name = "img-x1c7";
      extraMods = [
        nixosModules.clash
        nixosModules.home
        nixosModules.base
        nixosModules.gnome-desktop
        nixosModules.dcompass
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        agenix.nixosModules.age
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
      ];
      extraOverlays = [
        dcompass.overlays.default
        ash-emacs.overlays.default
      ];
      system = system.x86_64-linux;
    };

    nixosConfigurations.img-deck = mkSystem {
      name = "img-deck";
      extraMods = [
        nixosModules.clash
        nixosModules.home
        nixosModules.base
        nixosModules.gnome-desktop
        nixosModules.dcompass
        nixosModules.steamdeck
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        agenix.nixosModules.age
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
        jovian.nixosModules.default
      ];
      extraOverlays = [
        dcompass.overlays.default
        ash-emacs.overlays.default
      ];
      system = system.x86_64-linux;
    };

    # ISO image entry point
    imgs.x1c7 = nixosConfigurations.img-x1c7.config.system.build.isoImage;
    imgs.deck = nixosConfigurations.img-deck.config.system.build.isoImage;

    publicKey = "lexuge.cachix.org-1:RRFg8AxcexeBd33smnmcayMLU6r2wbVKbZHWtg2dKnY=";
  } // eachSystem [ system.x86_64-linux ] (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in
    {
      # Other than overlay, we have packages independently declared in flake.
      packages = (import ./pkgs {
        inherit lib;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      });

      # devShell used to launch agenix env.
      devShells.default = with import nixpkgs { inherit system; };
        mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          nativeBuildInputs = [ openssl agenix.packages.${system}.default nvfetcher.packages.${system}.default ];
        };

      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;

            shellcheck.enable = true;
            shfmt.enable = true;
          };
        };
      };

      apps = rec {
        update = utils.lib.mkApp {
          drv =
            pkgs.writeShellScriptBin "flake-update-nv" ''
              ${nvfetcher.packages.${system}.default}/bin/nvfetcher -c ./pkgs/nvfetcher.toml -o ./pkgs/_sources
            '';
        };
        default = update;
      };
    });
}
