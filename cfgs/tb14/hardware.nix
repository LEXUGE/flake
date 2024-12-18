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

  # TODO: TLP doesn't play well with GNOME. Try figure out how to do the charge threshold thing with UPower later.
  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     START_CHARGE_THRESH_BAT0 = 40; # 40 and bellow it starts to charge
  #     STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging
  #   };
  # };
}
