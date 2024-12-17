{ config, lib, ... }:
with lib;
let
  cfg = config.my.sing-box;
in
{
  options.my.sing-box = {
    enable = mkEnableOption "sing-box module including related systemd and networking setups";
    settings = mkOption {
      type = types.unspecified;
      description = ''
        Configuration
      '';
    };
  };
  config = mkIf cfg.enable {
    # sing-box requires IP forwarding
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    # Required by the sing-box TUN mode
    networking.firewall.trustedInterfaces = [ "tun0" ];
    networking.firewall.checkReversePath = "loose";

    services.sing-box = {
      enable = true;
      settings = cfg.settings;
    };

    systemd.services.sing-box.serviceConfig = {
      ProtectSystem = true;
      ProtectHome = true;
      PrivateTmp = true;
      RemoveIPC = true;
    };
  };
}
