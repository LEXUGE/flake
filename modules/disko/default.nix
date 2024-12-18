#WARN: Use of this module is deprecated. Use flake.nix to directly setup the diskoConfigurations and use in each system configuration instead.
{
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.my.disko;
in
{
  options.my.disko = {
    enable = mkEnableOption "Full-disk encrypted BTRFS and SWAP scheme for a single-disk setup";

    device = mkOption {
      type = types.str;
      default = "/dev/nvme0n1";
      description = "devices";
    };

    swap = mkOption {
      type = types.int;
      description = "Size of swap (in GiB)";
    };
  };

  config = mkIf cfg.enable {
    disko.devices = (
      import ./disk.nix {
        device = cfg.device;
        swap = cfg.swap;
      }
    );
  };
}
