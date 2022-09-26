{ config, lib, pkgs, modulesPath, ... }:
let
  cryptroot-uuid = "8f35ef6b-4dc4-48da-8389-bd2380571174";
  cryptswap-uuid = "116969f1-050c-42d3-886a-6bad84990cb8";
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

  fileSystems."/boot" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=boot" "noatime" "compress-force=zstd" ];
    # neededForBoot = true;
  };

  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/${cryptroot-uuid}";

  fileSystems."/boot/efi" = {
    label = "ESP";
    fsType = "vfat";
  };

  swapDevices =
    [{
      device = "/dev/mapper/cryptswap";
      encrypted = {
        enable = true;
        label = "cryptswap";
        keyFile = "/keyfile.bin"; # During stage-1, the neededForBoot device is mounted under /mnt-root
        blkDev = "/dev/disk/by-uuid/${cryptswap-uuid}";
      };
    }];

  # Hibernation doesn't seem to work
  # boot.resumeDevice = "/dev/mapper/cryptswap";

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
