{ config, ... }: {
  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
  };

  # Also the pub key used for age encryption
  users.users.ash.openssh.authorizedKeys.keys = let keys = import ../../secrets/keys.nix; in [ keys.ash_pubkey ];

  services.tor = {
    enable = true;
    openFirewall = true;
    relay = {
      enable = true;
      role = "bridge";
    };
    settings = {
      # ContactInfo = "toradmin@example.org";
      # Nickname = "toradmin";
      ORPort = 9001;
      AccountingStart = "week 1 10:00";
      # There is no AccountingRule in NixOS settings. Thus by default we are maxing out either send or receive.
      AccountingMax = "25 GBytes";
    };
  };

  services.nginx = {
    enable = true;

    clientMaxBodySize = "100M";

    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

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
