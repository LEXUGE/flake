{ config, ... }:
{
  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
  };

  # Also the pub key used for age encryption
  users.users.ash.openssh.authorizedKeys.keys =
    let
      keys = import ../../secrets/keys.nix;
    in
    [ keys.ash_pubkey ];

  services.tor = {
    enable = true;
    openFirewall = true;
    relay = {
      enable = true;
      role = "bridge";
    };
    settings = {
      ContactInfo = "dontcontact@cia.gov";
      # Nickname = "toradmin";
      ORPort = [
        {
          port = 8002;
          flags = [ "IPv4Only" ];
        }
      ];
      # ServerTransportPlugins are automatically set by nixpkgs
      ServerTransportListenAddr = "obfs4 0.0.0.0:8003";
      AccountingStart = "week 1 10:00";
      # There is no AccountingRule in NixOS settings. Thus by default we are maxing out either send or receive.
      AccountingMax = "25 GBytes";
    };
  };
  # obfs4 port
  networking.firewall.allowedTCPPorts = [ 8003 ];

  services.nginx = {
    enable = true;

    clientMaxBodySize = "100M";

    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    # eventsConfig = "worker_connections  4096;";
    # proxyTimeout = "3600s";

    virtualHosts."wormhole.flibrary.info" = {
      enableACME = true;
      forceSSL = true;
      # v2ray
      locations."/rayon" = {
        proxyWebsockets = true;
        proxyPass = "http://127.0.0.1:30800";
      };
    };
  };

  security.acme = {
    defaults.email = "lexugeyky@outlook.com";
    acceptTerms = true;
  };

  services.v2ray = {
    enable = true;
    configFile = config.age.secrets.v2ray_config.path;
  };
}
