{ config, lib, pkgs, ... }: {
  # An unused nameserver config. Trick the traffic to go through WAN and get routed by DAE
  networking.nameservers = [ "223.5.5.6" "8.8.8.8" ];

  networking.networkmanager = {
    # Enable networkmanager. REMEMBER to add yourself to group in order to use nm related stuff.
    enable = true;
    # Don't use DNS advertised by connected network. Use local configuration
    dns = "none";
    # Use the MAC Address same as my iPad
    wifi.scanRandMacAddress = true;
  };

  # Setup DAE
  services.dae = {
    enable = true;
    disableTxChecksumIpGeneric = false;
    configFile = config.age.secrets.dae_config.path;
    assets = with pkgs; [ v2ray-geoip v2ray-domain-list-community ];
    # Default tproxy Port
    openFirewall = {
      enable = true;
      port = 12345;
    };
  };

  # Allow users in daeusers to control dae without passwords.
  security.sudo.extraRules = [{
    groups = [ "daeusers" ];
    commands = [
      {
        command = "${pkgs.dae}/bin/dae";
        options = [ "NOPASSWD" "SETENV" ];
      }
      {
        command = "/run/current-system/sw/bin/dae";
        options = [ "NOPASSWD" "SETENV" ];
      }
    ];
  }];

  # Setup our local DNS
  my.dcompass = {
    enable = true;
    package = pkgs.dcompass.dcompass-maxmind;
    settings = (import ../../misc/dcompass_settings.nix { inherit pkgs; });
  };
}
