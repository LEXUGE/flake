{ config, pkgs, lib, ... }: {
  # Enable GVFS, implementing "trash" and so on.
  services.gvfs.enable = true;

  # Don't suspend if lid is closed with computer on power.
  services.logind.lidSwitchExternalPower = "lock";
  # Hybrid-sleep to survive through critical power level.
  services.logind.lidSwitch = "hybrid-sleep";

  # Enable GNU Agent in order to make GnuPG works.
  programs.gnupg.agent.enable = true;

  # Enable sound.
  sound.enable = true;

  # Configuration of pulseaudio to facilitate bluetooth headphones and Steam.
  hardware.pulseaudio = {
    enable = true;
    # 32 bit support for steam.
    support32Bit = true;
    # NixOS allows either a lightweight build (default) or full build of PulseAudio to be installed.
    # Only the full build has Bluetooth support, so it must be selected here.
    package = pkgs.pulseaudioFull;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # OpenGL 32 bit support for steam
  hardware.opengl.driSupport32Bit = true;

  # Enable fwupd service for firmware updates
  services.fwupd.enable = true;

  hardware.bluetooth = {
    enable = true;
    disabledPlugins = [ "sap" ];
  };
}
