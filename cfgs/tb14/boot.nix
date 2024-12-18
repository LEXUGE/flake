{
  config,
  lib,
  pkgs,
  ...
}:
{
  my.lanzaboote.enable = true;

  # Clean tmp folder which is a btrfs subvol
  boot.tmp.cleanOnBoot = true;

  # Create root on tmpfs
  fileSystems."/" = {
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=2G"
      "mode=755"
    ];
  };

  fileSystems."/persist".neededForBoot = true;

  # LUKS device registration and swap registration are already handled by disko
  # fallBackToPassword is implied by systemd-initrd
  boot.initrd.luks.devices."cryptroot" = {
    # keyFile = "/keyfile.bin";
    allowDiscards = true;
    # fallbackToPassword = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
