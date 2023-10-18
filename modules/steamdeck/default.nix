{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.steamdeck;
in {
  options.my.steamdeck = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    steam = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      user = mkOption {
        type = types.str;
        default = "deck";
      };
    };

    opensd = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      user = mkOption {
        type = types.str;
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      jovian.devices.steamdeck.enable = true;

      # Sounds are set up by Jovian NixOS
      hardware.pulseaudio.enable = lib.mkIf
        (config.jovian.devices.steamdeck.enableSoundSupport && config.services.pipewire.enable)
        (lib.mkForce false);
    })
    (mkIf (cfg.enable && cfg.opensd.enable) {
      users.groups.opensd = { };

      users.users."${cfg.opensd.user}".extraGroups = [ "opensd" ];

      services.udev.packages = [ pkgs.opensd ];

      # Enable OpenSD service
      home-manager.users."${cfg.opensd.user}".systemd.user.services.opensd = {
        Install = {
          WantedBy = [ "default.target" ];
        };

        Service = {
          ExecStart = "${pkgs.opensd}/bin/opensdd -l info";
        };
      };
    })
    (mkIf (cfg.enable && cfg.steam.enable) {
      jovian.steam = {
        autoStart = true;
        user = cfg.steam.user;
        enable = true;
        desktopSession = "gnome";
      };

      users.users."${cfg.steam.user}" = {
        isNormalUser = true;
        extraGroups = [ "networkmanager" ];
        hashedPassword = "$6$3CzXRRH.9GTAxZ2U$nG.C/YzFEKR7/SKWeGwEM9HvcNnSG655excCDR5YwpqOfzXw/zScsDmrBYJ8o1soN.yb4/BExdR0eG3xfJSEV0";
      };

      # services.xserver.displayManager.defaultSession = "steam-wayland";

      # services.xserver.displayManager.autoLogin.enable = true;
      # services.xserver.displayManager.autoLogin.user = cfg.steam.user;
      # services.xserver.displayManager.gdm.autoLogin.delay = 5;
    })
  ];
}
