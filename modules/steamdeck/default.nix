{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.steamdeck;
in
{
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
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      jovian.devices.steamdeck.enable = true;
    })
    (mkIf
      (
        cfg.enable && config.jovian.devices.steamdeck.enableSoundSupport && config.services.pipewire.enable
      )
      {
        # Sounds are set up by Jovian NixOS
        services.pulseaudio.enable = false;
      }
    )
    (mkIf (cfg.enable && cfg.steam.enable) {
      jovian.steam = {
        autoStart = true;
        user = cfg.steam.user;
        enable = true;
        desktopSession = "gnome";
      };
    })
  ];
}
