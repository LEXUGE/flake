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

      # Sounds are set up by Jovian NixOS
      hardware.pulseaudio.enable = lib.mkIf (
        config.jovian.devices.steamdeck.enableSoundSupport && config.services.pipewire.enable
      ) (lib.mkForce false);
    })
    (mkIf (cfg.enable && cfg.steam.enable) {
      jovian.steam = {
        autoStart = true;
        user = cfg.steam.user;
        enable = true;
        desktopSession = "gnome";
      };
      # jovian.decky-loader = {
      #   enable = true;
      # };
    })
  ];
}
