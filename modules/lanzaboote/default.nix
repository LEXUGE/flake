{
  lib,
  pkgs,
  config,
  ...
}:

with lib;

let
  cfg = config.my.lanzaboote;
in
{
  options.my.lanzaboote = {
    enable = mkEnableOption "Lanzaboote";
  };

  config = mkIf cfg.enable {
    # needed by lanzaboote
    boot.bootspec.enable = true;

    # Lanzaboote should be the only bootloader
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      publicKeyFile = "/etc/secureboot/keys/db/db.pem";
      privateKeyFile = "/etc/secureboot/keys/db/db.key";
    };

    # Enable firmwares otherwise we couldn't boot!
    hardware.enableAllFirmware = true;

    # Needed for systemd-cryptenroll
    boot.initrd.systemd.enable = true;
  };
}
