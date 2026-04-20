{ config, pkgs, ... }:
{
  networking.networkmanager = {
    # Enable networkmanager. REMEMBER to add yourself to group in order to use nm related stuff.
    enable = true;
    dns = "default";
  };

  # Setup DAE
  services.dae = {
    enable = true;
    disableTxChecksumIpGeneric = false;
    configFile = config.age.secrets.dae_config.path;
    assets = with pkgs; [
      v2ray-geoip
      v2ray-domain-list-community
    ];
    # Default tproxy Port
    openFirewall = {
      enable = true;
      port = 12345;
    };
  };

  # Setup our local DNS
  my.dcompass = {
    enable = true;
    package = pkgs.dcompass.dcompass-maxmind;
    settings = (import ../../misc/dcompass_settings.nix { inherit pkgs; });
  };
}
