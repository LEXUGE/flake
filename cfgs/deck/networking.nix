{ config, pkgs, ... }:
{
  networking.resolvconf.useLocalResolver = true;

  networking.networkmanager = {
    # Enable networkmanager. REMEMBER to add yourself to group in order to use nm related stuff.
    enable = true;
    # Don't use DNS advertised by connected network. Use local configuration
    dns = "none";
    # Use the MAC Address same as my iPad
    wifi.scanRandMacAddress = true;
  };

  my.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "info";
      };

      inbounds = [
        {
          type = "tun";
          # sing-box version is too old to support this
          # address = [
          #   "172.18.0.1/30"
          #   "fdfe:dcba:9876::1/126"
          # ];
          inet4_address = "172.19.0.1/30";
          inet6_address = "fdfe:dcba:9876::1/126";
          auto_route = true;
          strict_route = true;
          # sniff = true;
          # # Override IP addr with sniffed domain
          # sniff_override_destination = true;
        }
      ];

      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
        {
          _secret = config.age.secrets.sing-box.path;
          quote = false;
        }
      ];

      route = {
        rules = [
          {
            type = "logical";
            mode = "or";
            rules = [
              { ip_is_private = true; }
              { process_name = "dcompass"; }
              { process_name = "NetworkManager"; }
            ];
            outbound = "direct";
          }
          # TODO: This is deprecated and would be removed in the future.
          {
            geoip = [ "cn" ];
            geosite = [ "cn" ];
            outbound = "direct";
          }
        ];
        final = "proxy";
        auto_detect_interface = true;
      };
    };
  };

  # Setup our local DNS
  my.dcompass = {
    enable = true;
    package = pkgs.dcompass.dcompass-maxmind;
    settings = (import ../../misc/dcompass_settings.nix { inherit pkgs; });
  };
}
