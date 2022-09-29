{ config, lib, pkgs, modulesPath, ... }:
let
  cryptroot-uuid = "3c03d81c-6a7d-447d-8a20-19cfe33079f6";
  cryptswap-uuid = "4604a91b-5347-4371-a841-d9535ac1dc3d";
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # File system architecture:
  # / -> tmpfs
  # /nix -> (LUKSROOT -> BTRFSROOT -> nix)
  # /persist -> (LUKSROOT -> BTRFSROOT -> persist)
  # /persist/home -> (LUKSROOT -> BTRFSROOT -> persist -> home)
  # /boot (LUKSROOT -> BTRFSROOT -> boot)
  # /.snapshots (LUKSROOT -> BTRFSROOT -> .snapshots)
  # Other files are mapped by impermanence
  #
  # Also there is an encrypted swap partition.
  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=nix" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=persist" "noatime" "compress-force=zstd" ];
    # /persist is needed for boot cause it has to be present when impermanence's activation script runs.
    # otherwise it will be mounted after impermanence, which is unacceptable.
    neededForBoot = true;
  };

  fileSystems."/.snapshots" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=.snapshots" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/boot" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=boot" "noatime" "compress-force=zstd" ];
  };

  boot.initrd.luks.devices."cryptroot" = {
    device =
      "/dev/disk/by-uuid/${cryptroot-uuid}";
    keyFile = "/keyfile.bin";
    allowDiscards = true;
    fallbackToPassword = true;
  };

  # Manually decrypt swap partition to avoid decryption AFTER resuming in stage-1
  boot.initrd.luks.devices."cryptswap" = {
    device =
      "/dev/disk/by-uuid/${cryptswap-uuid}";
    keyFile = "/keyfile.bin";
    fallbackToPassword = true;
  };

  fileSystems."/boot/efi" = {
    label = "ESP";
    fsType = "vfat";
  };

  swapDevices =
    [{
      device = "/dev/mapper/cryptswap";
    }];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;

  hardware.enableAllFirmware = true;

  # Update Intel CPU Microcode
  hardware.cpu.intel.updateMicrocode = true;

  # Intel UHD 620 Hardware Acceleration
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-media-driver # only available starting nixos-19.03 or the current nixos-unstable
    ];
  };
}
