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
      AccountingMax = "50 GBytes";
    };
  };
  # obfs4 port
  networking.firewall.allowedTCPPorts = [ 8003 ];

  # Drains to much data
  services.snowflake-proxy = {
    enable = false;
    capacity = 16;
  };

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

  my.weathermon = {
    enable = false;
    providers = {
      met-london = {
        enable = true;
        schedule = "*:0/30";
        path = "/home/ash/persisted/weathermon/met-london";
        url = "https://weather.metoffice.gov.uk/forecast/gcpvn15h9";
      };
      accuweather-london = {
        enable = true;
        schedule = "hourly";
        path = "/home/ash/persisted/weathermon/accuweather-london";
        url = "https://www.accuweather.com/en/gb/london-city-airport/e16-2/daily-weather-forecast/5375_poi";
      };
      accuweather-nyc = {
        enable = true;
        schedule = "hourly";
        path = "/home/ash/persisted/weathermon/accuweather-nyc";
        url = "https://www.accuweather.com/en/us/laguardia-airport/11371/daily-weather-forecast/2627477";
      };
      noaa-london-observed = {
        enable = true;
        schedule = "*:0/30";
        path = "/home/ash/persisted/weathermon/noaa-london-observed";
        url = "https://tgftp.nws.noaa.gov/weather/current/EGLC.html";
      };
      noaa-nyc-observed = {
        enable = true;
        schedule = "*:0/30";
        path = "/home/ash/persisted/weathermon/noaa-nyc-observed";
        url = "https://tgftp.nws.noaa.gov/weather/current/KLGA.html";
      };
    };
  };

  my.orderbookmon = {
    enable = true;
    markets = {
      "07_31_london_temp" = {
        enable = false;
        path = "/home/ash/persisted/orderbookmon/weather";
        tokenIds = [
          "4574964205639575097071921564137745212460923611364541712959760381048123282126"
          "2284717961726247096457322071223346613439190518748501858092540128150710310015"
          "89991194577559130175927851346531761430740275581671427976162347837596964549198"
          "49194988479769947014190821731791350515721728624896777070853668307410304397939"
          "23675438689719972397523632963765393905381318621848495173233643828543600292067"
          "77755757007884693335669839412076830505628864085692427315389742705964366267750"
          "24589997911755678156730099691698120948471024689639003381041453629173348428536"
        ];
      };
      "08_01_london_temp" = {
        enable = false;
        path = "/home/ash/persisted/orderbookmon/weather";
        tokenIds = [
          "59107420328712502447193882350399903800977252851206213031089549215911145030863"
          "77184700551198388320310325793224965425824871362704570193598324341540349565396"
          "42124860985490794447817949171049412864785821247336513939032632806452693889458"
          "61340298234319848574557219426603969436053420650653010893107287987450688505945"
          "5595949716841487154442615694375316183690962970356329619647403614639891470813"
          "61776864659174637853494985087948147791784658747196718369740190398210720074456"
          "18375932401796516265717109861404966661123308607181473583870523837717578935706"
        ];

      };
    };
  };
}
