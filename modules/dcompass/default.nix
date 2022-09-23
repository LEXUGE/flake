{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.my.dcompass;
  confFile =
    pkgs.writeText "dcompass-config.json" (generators.toJSON { } cfg.settings);
in
{
  options.my.dcompass = {
    enable = mkEnableOption "Dcompass DNS server";

    package = mkOption {
      type = types.package;
      description = "Package of dcompass to use. e.g. pkgs.dcompass";
    };

    settings = mkOption {
      type = types.unspecified;
      description = ''
        Configuration file in JSON.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.dcompass = {
      description = "dcompass user";
      isSystemUser = true;
      group = "dcompass";
    };
    users.groups.dcompass = { };

    systemd.services.dcompass = {
      description = "Dcompass DNS service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = "${cfg.package}/bin/dcompass -c ${confFile}";
      serviceConfig = {
        # CAP_NET_BIND_SERVICE: Bind arbitary ports by unprivileged user.
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        User = "dcompass";
        Restart = "on-failure";
      };
    };
  };
}
