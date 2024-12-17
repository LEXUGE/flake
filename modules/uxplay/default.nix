{
  lib,
  pkgs,
  config,
  ...
}:

with lib;

let
  cfg = config.my.uxplay;
in
{
  options.my.uxplay = {
    enable = mkEnableOption "UxPlay";
  };

  config = mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish.enable = true;
      publish.userServices = true;
    };

    # If the -p option is not used, the ports are chosen dynamically (randomly), which will not work if a firewall is running.
    # These are the default ports for "-p"
    networking.firewall.allowedUDPPorts = [
      7011
      6001
      6000
    ];
    networking.firewall.allowedTCPPorts = [
      7100
      7000
      7001
    ];
  };
}
