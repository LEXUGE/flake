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

    opensdUser = mkOption
      {
        type = types.str;
      };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      jovian.devices.steamdeck.enable = true;

      # Sounds are set up by Jovian NixOS
      hardware.pulseaudio.enable = lib.mkIf
        (config.jovian.devices.steamdeck.enableSoundSupport && config.services.pipewire.enable)
        (lib.mkForce false);

      users.groups.opensd = { };

      users.users."${cfg.opensdUser}".extraGroups = [ "opensd" ];

      services.udev.packages = [ pkgs.opensd ];

      # Enable OpenSD service
      home-manager.users."${cfg.opensdUser}".systemd.user.services.opensd = {
        Unit = {
          WantedBy = [ "default.target" ];
        };

        Service = {
          ExecStart = "${pkgs.opensd}/bin/opensdd -l info";
        };
      };
    })
    (mkIf (cfg.enable && cfg.enableGaming) {
      jovian.steam.enable = true;

      users.users.deck = {
        isNormalUser = true;
        extraGroups = [ "networkmanager" ];
        # Allow the graphical user to login without password
        hashedPassword = "";
      };

      services.xserver.displayManager.defaultSession = "steam-wayland";
      services.xserver.displayManager.autoLogin.enable = true;
      services.xserver.displayManager.autoLogin.user = "deck";
    })
  ];
}
