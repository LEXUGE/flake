{
  description = "Deterministic Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    utils.url = "github:numtide/flake-utils";

    nvfetcher.url = "github:berberman/nvfetcher";
    nvfetcher.inputs.nixpkgs.follows = "nixpkgs";

    # Programmable DNS component used in our systems
    dcompass.url = "github:compassd/dcompass";
    # dcompass.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative Disk Management
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # My nvim configuration.
    vimrc.url = "github:LEXUGE/vimrc";
    # vimrc.inputs.nixpkgs.follows = "nixpkgs";

    # SecureBoot Management
    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    # Tool for NixOS on tmpfs
    impermanence.url = "github:nix-community/impermanence";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Reactivate standalone Home Manager profiles on ephemeral homes.
    rehomify.url = "github:nostorix/rehomify/0885d21d4653f4e514e1efe7d8fe9c1c7a1f96cd";

    # Secrets management
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # pre-commit hooks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sandbox
    guardian.url = "github:LEXUGE/guardian";
    guardian.inputs.nixpkgs.follows = "nixpkgs";

    # pi-coding agent
    pi-flake.url = "github:ChauDucToan/pi-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      nvfetcher,
      dcompass,
      impermanence,
      vimrc,
      home-manager,
      rehomify,
      agenix,
      disko,
      lanzaboote,
      pre-commit-hooks,
      guardian,
      pi-flake,
    }@inputs:
    with utils.lib;
    let
      lib = nixpkgs.lib;

      mkSystem =
        {
          name,
          extraMods ? [ ],
          extraOverlays ? [ ],
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
                  nix.settings.trusted-users = [ "@wheel" ];
                  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
                  nix.package = pkgs.nixVersions.latest;
                };
              }
            )
          ]
          ++ extraMods;
          specialArgs = {
            inherit inputs;
          }
          // extraArgs;
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

        };

        nixosModules = import ./modules/system { inherit lib; };

        homeConfigurations.ash = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = system.x86_64-linux;
            config.allowUnfree = true;
            overlays = [ vimrc.overlays.default ];
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./cfgs/tb14/home.nix ];
        };

        # Export system cfgs
        nixosConfigurations.tb14 = mkSystem {
          name = "tb14";
          extraMods = [
            nixosModules.tb-conservation
            nixosModules.base
            nixosModules.lanzaboote
            nixosModules.gnome-desktop
            nixosModules.dcompass
            nixosModules.timezone
            impermanence.nixosModules.impermanence
            rehomify.nixosModules.rehomify
            disko.nixosModules.disko
            lanzaboote.nixosModules.lanzaboote
            agenix.nixosModules.age
            { disko.devices = diskoConfigurations.tb14; }
          ];
          extraOverlays = [
            dcompass.overlays.default
            # WARN: Directly pulling in the overlay seems to break it due to nixpkgs incompatibility
            # (final: prev: {
            #   dcompass = {
            #     dcompass-maxmind = dcompass.outputs.packages."${system}".dcompass-maxmind;
            #   };
            # })
          ];
          system = system.x86_64-linux;
        };

        nixosConfigurations.img-tb14 = mkSystem {
          name = "img-tb14";
          extraMods = [
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

        diskoConfigurations = {
          tb14 = (import ./misc/disk.nix { swap = 40; });
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

        imgs.tb14 = nixosConfigurations.img-tb14.config.system.build.isoImage;
        imgs.shards-script = nixosConfigurations.shards.config.system.build.diskoImagesScript;

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
                  nixfmt = {
                    enable = true;
                  };

                  shellcheck = {
                    enable = true;
                    excludes = [ "\\.envrc" ];
                  };
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
