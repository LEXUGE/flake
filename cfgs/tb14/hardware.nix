{
  config,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Needed for boot! we didn't include these for steamdeck as Jovian did these for us.
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
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  # customized ideapad-laptop module
  boot.extraModulePackages =
    let
      sources = (import ../../pkgs/_sources/generated.nix) {
        inherit (pkgs)
          fetchurl
          fetchgit
          fetchFromGitHub
          dockerTools
          ;
      };
    in
    [
      (config.boot.kernelPackages.callPackage ../../pkgs/drivers/ideapad-thinkbook14/default.nix {
        source = sources.ideapad-thinkbook14;
      })
    ];
  boot.blacklistedKernelModules = [ "ideapad-laptop" ];
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
