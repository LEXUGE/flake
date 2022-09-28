{ pkgs, config, lib, ... }:

with lib;

let
  inherit (lib) optionalString mkIf;
  cfg = config.my.clash;
  inherit (cfg) clashUserName;
  tproxyPortStr = toString cfg.tproxyPort;

  # Run iptables 4 and 6 together.
  # NOTE: IPv6 TPROXY only works if bind-address: '*' is set so clash listens to both IPv6 and IPv4 addresses
  helper = ''
    ip46tables() {
      iptables -w "$@"
      ${
        optionalString config.networking.enableIPv6 ''
          ip6tables -w "$@"
        ''
      }
    }
  '';

  tag = "CLASH_SPEC";
  tag_local = "CLASH_SPEC_LOCAL";

  # Defined per https://en.wikipedia.org/wiki/Reserved_IP_addresses
  reservedIPv4Addrs = [
    "0.0.0.0/8"
    "10.0.0.0/8"
    "100.64.0.0/10"
    "127.0.0.0/8"
    "169.254.0.0/16"
    "172.16.0.0/12"
    "192.0.0.0/24"
    "192.0.2.0/24"
    "192.88.99.0/24"
    "192.168.0.0/16"
    "198.18.0.0/15"
    "198.51.100.0/24"
    "203.0.113.0/24"
    "224.0.0.0/4"
    "233.252.0.0/24"
    "240.0.0.0/4"
    "255.255.255.255/32"
  ];

  reservedIPv6Addrs = [
    # "::/0"
    "::/128"
    "::1/128"
    "::ffff:0:0/96"
    "::ffff:0:0:0/96"
    "64:ff9b::/96"
    "64:ff9b:1::/48"
    "100::/64"
    "2001:0000::/32"
    "2001:20::/28"
    "2001:db8::/32"
    "2002::/16"
    "fc00::/7"
    "fe80::/10"
    "ff00::/8"
  ];

  clashModule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Clash transparent proxy module.";
      };

      configPath = mkOption {
        type = types.path;
        description = "Path to the Clash config file.";
      };

      dashboard.port = mkOption {
        type = types.port;
        default = 3333;
        description = "Port for YACD dashboard to listen on.";
      };

      clashUserName = mkOption {
        type = types.str;
        default = "clash";
        description =
          "The user who would run the clash proxy systemd service. User would be created automatically.";
      };

      tproxyPort = mkOption {
        type = types.port;
        default = 7893;
        description =
          "Clash tproxy-port";
      };

      afterUnits = mkOption {
        type = with types; listOf str;
        default = [ ];
        description =
          "List of systemd units that need to be started after clash. Note this is placed in `before` parameter of clash's systemd config.";
      };

      requireUnits = mkOption {
        type = with types; listOf str;
        default = [ ];
        description =
          "List of systemd units that need to be required by clash.";
      };

      beforeUnits = mkOption {
        type = with types; listOf str;
        default = [ ];
        description =
          "List of systemd units that need to be started before clash. Note this is placed in `after` parameter of clash's systemd config.";
      };
    };
  };
in
{
  options.my.clash = mkOption {
    type = clashModule;
    default = { };
    description = "Clash system service related configurations";
  };

  config = mkIf (cfg.enable) {
    environment.etc."clash/Country.mmdb".source =
      "${pkgs.maxmind-geoip}/Country.mmdb"; # Bring pre-installed geoip data into directory.
    environment.etc."clash/config.yaml".source = cfg.configPath;

    # Yacd
    services.lighttpd = {
      enable = true;
      port = cfg.dashboard.port;
      document-root = "${pkgs.yacd}/bin";
    };

    users.users.${clashUserName} = {
      description = "Clash deamon user";
      isSystemUser = true;
      group = "clash";
    };
    users.groups.clash = { };

    # Use networkd to manage our local loopback
    #
    # [Match]
    # Name = lo
    #
    # [RoutingPolicyRule]
    # FirewallMark = 1
    # Table = 100
    # Priority = 100
    #
    # [Route]
    # Table = 100
    # Destination = 0.0.0.0/0
    # Type = local

    # Don't use resolved which is enabled by default once networkd is enabled
    # This priority is higher than mkDefault (1000), but less than manual definition
    services.resolved.enable = mkOverride 999 false;
    systemd.network = {
      enable = true;
      networks.lo = {
        # equivalent to matchConfig.Name = "lo";
        name = "lo";
        routingPolicyRules = [{
          # Route all packets with firewallmark 1 (set by iptables in output chain) using table "100" which says go to loopback
          routingPolicyRuleConfig = { FirewallMark = 1; Table = 100; Priority = 100; };
        }
          { routingPolicyRuleConfig = { From = "::/0"; FirewallMark = 1; Table = 100; Priority = 100; }; }];
        routes = [
          # Create a table that routes to loopback
          { routeConfig = { Table = 100; Destination = "0.0.0.0/0"; Type = "local"; }; }
          { routeConfig = { Table = 100; Destination = "::/0"; Type = "local"; }; }
        ];
      };
    };

    # If the user doesn't have any other interface managed by networkd, then there will be no interface managed (lo is ignored by default)
    # This makes networkd-wait-online impossible to succeed.
    # Thus let's disable on default
    systemd.services.systemd-networkd-wait-online = {
      enable = mkDefault false;
      restartIfChanged = mkDefault false;
    };

    systemd.services.clash =
      let
        preStartScript = pkgs.writeShellScript "clash-prestart" ''
          ${helper}
          # Clear the chain to avoid unnecessary incident.
          ip46tables -t mangle -F ${tag}
          # Create a new chain appending at the end.
          ip46tables -t mangle -N ${tag}

          # Don't intercept packets sent to any of the reserved IP addresses
          # Otherwise all responses from clash to "local" application will be routed back to clash again
          ${concatStringsSep "\n" (map (addr: "iptables -w -t mangle -A ${tag} -d ${addr} -j RETURN") reservedIPv4Addrs)}
          ${concatStringsSep "\n" (map (addr: "ip6tables -w -t mangle -A ${tag} -d ${addr} -j RETURN") reservedIPv6Addrs)}

          # Intercept all traffic to clash otherwise. Note by default TPROXY implies local IP which is desired.
          ip46tables -t mangle -A ${tag} -p tcp -j TPROXY --on-port ${tproxyPortStr}
          ip46tables -t mangle -A ${tag} -p udp -j TPROXY --on-port ${tproxyPortStr}
          ip46tables -t mangle -A PREROUTING -j ${tag}

          # Hacks to make TPROXY work on local orginated traffics
          ip46tables -t mangle -F ${tag_local}
          ip46tables -t mangle -N ${tag_local}

          # Don't intercept local packets sent to any of the reserved IP addresses.
          # Even this is not necessary, it eliminates the need to exempt these traffics in clash config and expedite the routing as otherwise these packets will be routed again.
          ${concatStringsSep "\n" (map (addr: "iptables -w -t mangle -A ${tag_local} -d ${addr} -j RETURN") reservedIPv4Addrs)}
          ${concatStringsSep "\n" (map (addr: "ip6tables -w -t mangle -A ${tag_local} -d ${addr} -j RETURN") reservedIPv6Addrs)}

          # Don't forward package created by ${clashUserName}. Since after forwarding by clash the packets' owner would be changed to ${clashUserName}, this helps us to avoid dead loop in packet forwarding.
          ip46tables -t mangle -A ${tag_local} -m owner --uid-owner ${clashUserName} -j RETURN
          # Set mark 1 for all local traffic. This will let policy routing table route it back to us again (without altering actual packet), making local -> remote packets going through TPROXY as defined above
          ip46tables -t mangle -A ${tag_local} -p tcp -j MARK --set-mark 1
          ip46tables -t mangle -A ${tag_local} -p udp -j MARK --set-mark 1
          ip46tables -t mangle -A OUTPUT -j ${tag_local}
        '';

        # tag_local is included when grepping tag.
        postStopScript = pkgs.writeShellScript "clash-poststop" ''
          iptables-save -c|grep -v ${tag}|iptables-restore -c
          ${optionalString config.networking.enableIPv6 ''
            ip6tables-save -c|grep -v ${tag}|ip6tables-restore -c
          ''}
        '';
      in
      {
        path = with pkgs; [ gnugrep iptables clash ];
        description = "Clash networking service";
        after = [ "network.target" ] ++ cfg.beforeUnits;
        before = cfg.afterUnits;
        requires = cfg.requireUnits;
        wantedBy = [ "multi-user.target" ];
        script =
          "exec clash -d /etc/clash"; # We don't need to worry about whether /etc/clash is reachable in Live CD or not. Since it would never be execuated inside LiveCD.

        # Don't start if the config file doesn't exist.
        unitConfig = {
          # NOTE: configPath is for the original config which is linked to the following path.
          ConditionPathExists = "/etc/clash/config.yaml";
        };
        serviceConfig = {
          # Use prefix `+` to run iptables as root.
          ExecStartPre = "+${preStartScript}";
          ExecStopPost = "+${postStopScript}";
          # CAP_NET_BIND_SERVICE: Bind arbitary ports by unprivileged user.
          # CAP_NET_ADMIN: Listen on UDP.
          AmbientCapabilities =
            "CAP_NET_BIND_SERVICE CAP_NET_ADMIN"; # We want additional capabilities upon a unprivileged user.
          User = clashUserName;
          Restart = "on-failure";
        };
      };
  };
}
