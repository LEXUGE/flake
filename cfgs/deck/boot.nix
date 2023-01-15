{ config, lib, pkgs, ... }: {
  # Enable plymouth for better booting cosmetics
  # Plymouth seems to falter GDM from starting up.
  # boot.plymouth.enable = true;

  # Enable firmwares otherwise we couldn't boot!
  hardware.enableAllFirmware = true;

  # Needed for systemd-cryptenroll
  boot.initrd.systemd.enable = true;

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

  # Already handled by disko
  # swapDevices =
  #   [{
  #     device = "/dev/mapper/cryptswap";
  #   }];

  # fallBackToPassword is implied by systemd-initrd
  boot.initrd.luks.devices."cryptroot" = {
    # keyFile = "/keyfile.bin";
    allowDiscards = true;
    # fallbackToPassword = true;
  };

  # Manually decrypt swap partition to avoid decryption AFTER resuming in stage-1
  # boot.initrd.luks.devices."cryptswap" = {
  #   keyFile = "/keyfile.bin";
  #   fallbackToPassword = true;
  # };
}
