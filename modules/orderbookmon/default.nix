{
  lib,
  pkgs,
  config,
  ...
}:

with lib;

let
  cfg = config.my.orderbookmon;

  mappedMarkets = mapAttrsToList (
    name: market:
    (mkIf market.enable {
      timers."orderbookmon-${name}" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = market.schedule;
          # If somehow computer is down, run once more after it becomes available
          Persistent = true;
          Unit = "orderbookmon-${name}.service";
        };
      };

      # It's better to have the visibility on network issues by looking into the journal error message.
      services."orderbookmon-${name}" =
        let
          clob_api_url = "https://clob.polymarket.com/books";
          tokenIdJSON = builtins.toJSON (map (id: { token_id = id; }) market.tokenIds);
          startScript = pkgs.writeShellScript "orderbookmon-${name}-start" ''
            curl -f -s -o ${market.path}/${name}_$(date +\%Y\%m\%d-\%H\%M\%S) ${clob_api_url} -X POST -d ${strings.escapeShellArg tokenIdJSON}
          '';
        in
        {
          description = "Order Book Monitoring Service for ${name}";
          path = with pkgs; [
            curl
            coreutils
          ];
          serviceConfig = {
            Type = "oneshot";
            # systemd uses %% to escape % in ExecStart
            ExecStart = "${startScript}";
          };
        };
    })
  ) cfg.markets;

  marketOptions = {
    options = {
      enable = mkEnableOption "Specific Market";
      path = mkOption {
        type = types.str;
        description = "Path to save data, no trailing slash";
      };
      tokenIds = mkOption {
        type = with types; listOf str;
        description = "Token IDs of order books to monitor";
      };
      schedule = mkOption {
        type = types.str;
        default = "*:*:0/30"; # Every 30 seconds
        description = "Systemd timer schedule for this market";
      };
    };
  };
in
{
  options.my.orderbookmon = {
    enable = mkEnableOption "Order Book Monitoring Service";
    markets = mkOption {
      type = with types; attrsOf (submodule marketOptions);
      description = "List of markets to monitor.";
    };
  };

  # Workaround the infinite recursion
  config.systemd = mkIf cfg.enable (mkMerge mappedMarkets);
}
