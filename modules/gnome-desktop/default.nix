{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.gnome-desktop;
in {
  options.my.gnome-desktop = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    enableDisplayManager = mkOption {
      type = types.bool;
      default = true;
    };

    extraExcludePackages = mkOption {
      type = with types; listOf package;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      # Start X11
      enable = true;

      # Capslock as Control
      xkbOptions = "ctrl:nocaps";

      # Configure touchpad
      libinput = {
        enable = true;
        touchpad.naturalScrolling = true;
      };
    };

    services.xserver = {
      displayManager.gdm.enable = cfg.enableDisplayManager;
      desktopManager.gnome.enable = true;
    };

    # Some of the GNOME Packages are unwanted
    programs.geary.enable = false;
    environment.gnome.excludePackages = with pkgs.gnome; [
      epiphany # GNOME Web
      gnome-software
      gnome-characters
    ] ++ cfg.extraExcludePackages;
  };
}
