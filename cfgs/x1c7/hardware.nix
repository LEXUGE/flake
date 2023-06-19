{ pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Needed for boot! we didn't include these for steamdeck as Jovian did these for us.
  boot.initrd.availableKernelModules =
    [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.enableRedistributableFirmware = true;

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
