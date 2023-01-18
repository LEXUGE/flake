{ config, lib, pkgs, ... }: {
  # needed by lanzaboote
  boot.bootspec.enable = true;

  # Lanzaboote should be the only bootloader
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    publicKeyFile = config.age.secrets.secureboot_db_cert.path;
    privateKeyFile = config.age.secrets.secureboot_db_key.path;
  };

  # Enable firmwares otherwise we couldn't boot!
  hardware.enableAllFirmware = true;

  # Needed for systemd-cryptenroll
  boot.initrd.systemd.enable = true;

  # Clean tmp folder which is a btrfs subvol
  boot.cleanTmpDir = true;

  # Handled by lanzaboote
  # boot.loader = {
  #   systemd-boot.enable = true;
  # };

  # Create root on tmpfs
  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/persist".neededForBoot = true;

  # LUKS device registration and swap registration are already handled by disko
  # fallBackToPassword is implied by systemd-initrd
  boot.initrd.luks.devices."cryptroot" = {
    # keyFile = "/keyfile.bin";
    allowDiscards = true;
    # fallbackToPassword = true;
  };
}
