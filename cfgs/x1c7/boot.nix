{ config, lib, pkgs, ... }: {
  # Enable plymouth for better booting cosmetics
  # Plymouth seems to falter GDM from starting up.
  # boot.plymouth.enable = true;

  # Use Keyfile to unlock the root partition to avoid keying in twice.
  # Allow fstrim to work on it.
  boot.initrd = {
    secrets = { "/keyfile.bin" = "/persist/secrets/keyfile.bin"; };
    luks.devices."cryptroot" = {
      keyFile = "/keyfile.bin";
      allowDiscards = true;
      fallbackToPassword = true;
    };
  };

  # Use GRUB with encrypted /boot under EFI env.
  boot.loader = {
    efi = {
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      version = 2;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
      enableCryptodisk = true;
    };
  };
}
