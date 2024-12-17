{
  lib,
  pkgs,
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
  };

  config = mkIf cfg.enable {
    disko.devices = (import ./disk.nix { device = cfg.device; });
  };
}
