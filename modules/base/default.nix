{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.my.base;
in
{
  options.my.base = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    hostname = mkOption {
      type = types.str;
      description = "The hostname of the system";
    };

    lockdownKernel = mkOption
      {
        type = types.bool;
        default = true;
        description = "Lockdown Kernel modules by signing them with a key or not";
      };
  };

  config = mkMerge [
    (mkIf cfg.enable
      (
        {
          networking.hostName = cfg.hostname;

          boot.kernelPackages = pkgs.linuxPackages_latest;

          # Support NTFS
          boot.supportedFilesystems = [ "ntfs" ];

          # Auto upgrade
          # system.autoUpgrade.enable = true;

          # deploy-rs doesn't play well with wheel passwords when deploying, better to disable it.
          security.sudo.wheelNeedsPassword = false;

          # Enable flake
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';

          # Auto gc and optimise
          nix.optimise.automatic = true;
          nix.gc.automatic = false;
          nix.gc.options = "--delete-older-than 7d";

          # Allow unfree packages
          nixpkgs.config.allowUnfree = true;

          environment.systemPackages = with pkgs; [ wget coreutils-full git ];
        }
      ))
    (mkIf cfg.lockdownKernel ({
      # Lockdown kernel modules by signing them with random key
      boot.kernelParams = [
        "lockdown=integrity"
      ];
      boot.kernelPatches = [
        # this patch makes the linux kernel unreproducible
        {
          name = "lockdown";
          patch = null;
          extraConfig = ''
            MODULE_SIG y
            SECURITY_LOCKDOWN_LSM y
          '';
        }
      ];
      assertions = [
        {
          assertion = lib.length config.boot.extraModulePackages == 0;
          message = "out-of-tree and unsigned kernel module";
        }
      ];
    }))
  ];
}
