{ config, pkgs, lib, ... }: {
  ### Power and hardware
  # Enable fwupd service for firmware updates
  services.fwupd.enable = true;

  hardware.bluetooth = {
    enable = true;
    disabledPlugins = [ "sap" ];
  };

  # Don't suspend if lid is closed with computer on power.
  services.logind.lidSwitchExternalPower = "lock";
  # suspend-then-hibernate to survive through critical power level.
  services.logind.lidSwitch = "suspend-then-hibernate";

  ### Sound and graphics
  # Enable sound.
  # sound.enable = true;

  # Configuration of pulseaudio to facilitate bluetooth headphones and Steam.
  hardware.pulseaudio = {
    enable = true;
    # 32 bit support for steam.
    support32Bit = true;
    # NixOS allows either a lightweight build (default) or full build of PulseAudio to be installed.
    # Only the full build has Bluetooth support, so it must be selected here.
    package = pkgs.pulseaudioFull;
  };

  # OpenGL 32 bit support for steam
  hardware.graphics.enable32Bit = true;

  ### Misc
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable GVFS, implementing "trash" and so on.
  services.gvfs.enable = true;

  # Enable GNU Agent in order to make GnuPG works.
  programs.gnupg.agent.enable = true;

  # Use btrbk to snapshot persistent states and home
  services.btrbk.instances.snapshot = {
    # snapshot on the start and the middle of every hour.
    onCalendar = "*:00,30";
    settings = {
      timestamp_format = "long-iso";
      preserve_day_of_week = "monday";
      preserve_hour_of_day = "23";
      # All snapshots are retained for at least 6 hours regardless of other policies.
      snapshot_preserve_min = "6h";
      volume."/" = {
        snapshot_dir = ".snapshots";
        subvolume."persist".snapshot_preserve = "48h 7d";
        subvolume."persist/home".snapshot_preserve = "48h 7d 4w";
      };
    };
  };

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark-qt;
  };

  # Required to enable completion somehow.
  programs.zsh.enable = true;

  # Scrub btrfs to protect data integrity
  services.btrfs.autoScrub.enable = true;

  # setup uxplay related services
  my.uxplay.enable = true;
}
