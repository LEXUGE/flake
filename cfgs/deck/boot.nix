{ config, lib, pkgs, ... }: {
  # Enable plymouth for better booting cosmetics
  # Plymouth seems to falter GDM from starting up.
  # boot.plymouth.enable = true;

  # Use Keyfile to unlock the root partition to avoid keying in twice.
  # Allow fstrim to work on it.
  # boot.initrd.secrets = { "/keyfile.bin" = "/persist/secrets/keyfile.bin"; };

  # Use systemd and default ESP setup (i.e. /boot as ESP)
  # This is disabled because lanzaboote will be in use
  # See also ./secureboot.nix
  boot.loader = {
    systemd-boot.enable = true;
  };

  # Create root on tmpfs
  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/persist".neededForBoot = true;

  swapDevices =
    [{
      device = "/dev/mapper/cryptswap";
    }];

  boot.initrd.luks.devices."cryptroot" = {
    # keyFile = "/keyfile.bin";
    allowDiscards = true;
    fallbackToPassword = true;
  };

  # Manually decrypt swap partition to avoid decryption AFTER resuming in stage-1
  boot.initrd.luks.devices."cryptswap" = {
    # keyFile = "/keyfile.bin";
    fallbackToPassword = true;
  };
}
