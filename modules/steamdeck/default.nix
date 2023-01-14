{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.steamdeck;
in {
  options.my.steamdeck = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    enableGaming = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    jovian.devices.steamdeck.enable = true;

    jovian.steam.enable = cfg.enableGaming;

    # Sounds are set up by Jovian NixOS
    hardware.pulseaudio.enable = lib.mkIf
      (config.jovian.devices.steamdeck.enableSoundSupport && config.services.pipewire.enable)
      (lib.mkForce false);
  };
}
