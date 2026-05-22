{
  config,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Needed for boot on this hardware profile.
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "thunderbolt"
  ];
  boot.kernelParams = [
    # Disable NMI watchdog to save power
    "kernel.nmi_watchdog=0"
    "pcie_aspm.policy=powersupersave"
    # Workaround random GPU crash
    # https://gitlab.freedesktop.org/drm/amd/-/issues/3647
    "amdgpu.dcdebugmask=0x10"
    # Workaround ROCm GPU hang
    # https://github.com/ROCm/TheRock/issues/1264
    "amdgpu.cwsr_enable=0"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];

  # boot.resumeDevice = "/dev/mapper/cryptswap";

  hardware.enableRedistributableFirmware = true;

  # Update AMD CPU Microcode
  hardware.cpu.amd.updateMicrocode = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  my.tb-conservation.enable = true;
}
