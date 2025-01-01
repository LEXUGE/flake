{
  description = "Deterministic Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pin a nixpkgs for mathematica to prevent it from rebiulding everytime dependency updates.
    nixpkgs-mathematica.url = "github:nixos/nixpkgs/8a3354191c0d7144db9756a74755672387b702ba";

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
    ash-emacs.inputs.nixpkgs.follows = "nixpkgs";

    # My nvim configuration.
    vimrc.url = "github:LEXUGE/vimrc";
    vimrc.inputs.nixpkgs.follows = "nixpkgs";

    # SecureBoot Management
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";
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

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-mathematica,
      utils,
      nvfetcher,
      dcompass,
      impermanence,
      vimrc,
      ash-emacs,
      home-manager,
      agenix,
      disko,
      jovian,
      lanzaboote,
      pre-commit-hooks,
    }@inputs:
    with utils.lib;
    let
      lib = nixpkgs.lib;

      mkSystem =
        {
          name,
          extraMods ? [ ],
          extraOverlays ? [ ],
          extraSubstituters ? [ ],
          extraPublicKeys ? [ ],
          extraArgs ? { },
          system,
        }:
        (lib.nixosSystem {
          inherit system;
          modules = [
            ./cfgs/${name}
            (
              { pkgs, config, ... }:
              {
                config = {
                  nixpkgs.overlays = [ self.overlays.default ] ++ extraOverlays;
                  nix.settings = {
                    substituters = [
                      "https://dcompass.cachix.org"
                      "https://nix-community.cachix.org"
                      "https://lexuge.cachix.org"
                    ] ++ extraSubstituters;
                    trusted-public-keys = [
                      dcompass.publicKey
                      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                      self.publicKey
                    ] ++ extraPublicKeys;
                    trusted-users = [ "@wheel" ];
                  };
                  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
                  nix.package = pkgs.nixVersions.latest;
                };
              }
            )
          ] ++ extraMods;
          specialArgs = {
            inherit inputs;
          } // extraArgs;
        });
    in
    nixpkgs.lib.recursiveUpdate
      rec {
        # Use the default overlay to export all packages under ./pkgs
        overlays = {
          default =
            final: prev:
            (import ./pkgs {
              inherit (prev) lib;
              pkgs = prev;
              overlay = true;
            });
          # # Currently not used, but put here as an example
          # pidgin = final: prev: {
          #   pidgin-with-plugins = prev.pidgin.override {
          #     plugins = [ prev.pidgin-otr ];
          #   };
          # };

          mem-cap = final: prev: {
            zotero = prev.buildEnv {
              name = "zotero-mem-cap-suite";
              # Intentional, other schemes may take up twice of storage and possibly a rebuild
              ignoreCollisions = false;
              paths = [
                # uncapped version
                (prev.writeShellScriptBin "zotero-mem-uncapped" ''
                  ${prev.zotero}/bin/zotero "$@"
                '')
                # capped version
                (lib.hiPrio (
                  prev.writeShellScriptBin "zotero" ''
                    ${prev.systemd}/bin/systemd-run --user --scope -p MemoryHigh=4G ${prev.zotero}/bin/zotero "$@"
                  ''
                ))
                prev.zotero
              ];
            };

            firefox = prev.buildEnv {
              name = "firefox-mem-cap-suite";
              # Intentional, other schemes may take up twice of storage and possibly a rebuild
              ignoreCollisions = false;
              paths = [
                # uncapped version
                (prev.writeShellScriptBin "firefox-mem-uncapped" ''
                  ${prev.firefox}/bin/firefox "$@"
                '')
                # capped version
                (lib.hiPrio (
                  prev.writeShellScriptBin "firefox" ''
                    ${prev.systemd}/bin/systemd-run --user --scope -p MemoryHigh=4G ${prev.firefox}/bin/firefox "$@"
                  ''
                ))
                prev.firefox
              ];
            };
          };
        };

        # Export modules under ./modules as NixOS modules
        nixosModules = (import ./modules { inherit lib; });

        # Export system cfgs
        nixosConfigurations.tb14 = mkSystem {
          name = "tb14";
          extraMods = [
            nixosModules.tb-conservation
            nixosModules.clash
            nixosModules.base
            nixosModules.lanzaboote
            nixosModules.uxplay
            nixosModules.home
            nixosModules.gnome-desktop
            nixosModules.dcompass
            nixosModules.sing-box
            nixosModules.timezone
            impermanence.nixosModules.impermanence
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            lanzaboote.nixosModules.lanzaboote
            agenix.nixosModules.age
            { disko.devices = diskoConfigurations.tb14; }
          ];
          extraOverlays = [
            dcompass.overlays.default
            ash-emacs.overlays.emacs-overlay
            ash-emacs.overlays.default
            vimrc.overlays.default
            self.overlays.mem-cap
          ];
          system = system.x86_64-linux;
        };

        nixosConfigurations.img-tb14 = mkSystem {
          name = "img-tb14";
          extraMods = [
            nixosModules.home
            nixosModules.base
            nixosModules.gnome-desktop
            nixosModules.dcompass
            nixosModules.image-base
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            agenix.nixosModules.age
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
            { disko.devices = diskoConfigurations.tb14; }
          ];
          extraOverlays = [
            dcompass.overlays.default
            vimrc.overlays.default
          ];
          system = system.x86_64-linux;
        };

        # Export system cfgs
        nixosConfigurations.x1c7 = mkSystem {
          name = "x1c7";
          # extraSubstituters = [ "https://nixbld.m-labs.hk" ];
          # extraPublicKeys = [ "nixbld.m-labs.hk-1:5aSRVA5b320xbNvu30tqxVPXpld73bhtOeH6uAjRyHc=" ];
          extraMods = [
            nixosModules.clash
            nixosModules.base
            nixosModules.lanzaboote
            nixosModules.uxplay
            nixosModules.home
            nixosModules.gnome-desktop
            nixosModules.dcompass
            nixosModules.sing-box
            nixosModules.timezone
            impermanence.nixosModules.impermanence
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            lanzaboote.nixosModules.lanzaboote
            agenix.nixosModules.age
            { disko.devices = diskoConfigurations.x1c7; }
          ];
          extraOverlays = [
            dcompass.overlays.default
            ash-emacs.overlays.emacs-overlay
            ash-emacs.overlays.default
            vimrc.overlays.default
          ];
          system = system.x86_64-linux;
        };

        diskoConfigurations = {
          deck = (import ./modules/disko/disk.nix { swap = 20; });
          x1c7 = (import ./modules/disko/disk.nix { swap = 20; });
          tb14 = (import ./modules/disko/disk.nix { swap = 40; });
          shards = (import ./cfgs/shards/disk-config.nix { });
        };

        # Deploy using nixos-rebuild directly
        # https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment#deploy-through-nixos-rebuild
        nixosConfigurations.shards = mkSystem {
          name = "shards";
          extraMods = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            agenix.nixosModules.age
          ];
          system = system.x86_64-linux;
        };

        # Deploy using nixos-rebuild directly
        # https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment#deploy-through-nixos-rebuild
        nixosConfigurations.deck = mkSystem {
          name = "deck";
          extraMods = [
            nixosModules.clash
            nixosModules.base
            nixosModules.lanzaboote
            nixosModules.home
            nixosModules.gnome-desktop
            nixosModules.dcompass
            nixosModules.sing-box
            nixosModules.timezone
            disko.nixosModules.disko
            nixosModules.steamdeck
            impermanence.nixosModules.impermanence
            home-manager.nixosModules.home-manager
            agenix.nixosModules.age
            lanzaboote.nixosModules.lanzaboote
            jovian.nixosModules.default
            { disko.devices = diskoConfigurations.deck; }
          ];
          extraOverlays = [
            dcompass.overlays.default
            ash-emacs.overlays.emacs-overlay
            ash-emacs.overlays.default
            vimrc.overlays.default
          ];
          system = system.x86_64-linux;
        };

        nixosConfigurations.img-x1c7 = mkSystem {
          name = "img-x1c7";
          extraMods = [
            nixosModules.home
            nixosModules.base
            nixosModules.gnome-desktop
            nixosModules.dcompass
            nixosModules.image-base
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            agenix.nixosModules.age
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
            { disko.devices = diskoConfigurations.x1c7; }
          ];
          extraOverlays = [
            dcompass.overlays.default
            vimrc.overlays.default
          ];
          system = system.x86_64-linux;
        };

        nixosConfigurations.img-deck = mkSystem {
          name = "img-deck";
          extraMods = [
            nixosModules.home
            nixosModules.base
            nixosModules.gnome-desktop
            nixosModules.dcompass
            nixosModules.steamdeck
            nixosModules.image-base
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            agenix.nixosModules.age
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
            jovian.nixosModules.default
            { disko.devices = diskoConfigurations.deck; }
          ];
          extraOverlays = [
            dcompass.overlays.default
            vimrc.overlays.default
          ];
          system = system.x86_64-linux;
        };

        # ISO image entry point
        imgs.x1c7 = nixosConfigurations.img-x1c7.config.system.build.isoImage;
        imgs.deck = nixosConfigurations.img-deck.config.system.build.isoImage;
        imgs.tb14 = nixosConfigurations.img-tb14.config.system.build.isoImage;

        publicKey = "lexuge.cachix.org-1:RRFg8AxcexeBd33smnmcayMLU6r2wbVKbZHWtg2dKnY=";
      }
      (
        eachSystem [ system.x86_64-linux ] (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            # Other than overlay, we have packages independently declared in flake.
            packages = (
              import ./pkgs {
                inherit lib;
                pkgs = import nixpkgs {
                  inherit system;
                  overlays = [ self.overlays.default ];
                };
              }
            );

            # devShell used to launch agenix env.
            devShells.default =
              with import nixpkgs { inherit system; };
              mkShell {
                inherit (self.checks.${system}.pre-commit-check) shellHook;
                nativeBuildInputs = [
                  openssl
                  agenix.packages.${system}.default
                  nvfetcher.packages.${system}.default
                ];
              };

            checks = {
              pre-commit-check = pre-commit-hooks.lib.${system}.run {
                src = ./.;
                hooks = {
                  nixfmt-rfc-style.enable = true;

                  shellcheck.enable = true;
                  shfmt.enable = true;
                };
              };
            };

            apps = rec {
              update = utils.lib.mkApp {
                drv = pkgs.writeShellScriptBin "flake-update-nv" ''
                  ${nvfetcher.packages.${system}.default}/bin/nvfetcher -c ./pkgs/nvfetcher.toml -o ./pkgs/_sources
                '';
              };
              default = update;
            };
          }
        )
      );
}
