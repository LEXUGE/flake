{
  lib,
  pkgs,
  config,
  ...
}:

with lib;

let
  cfg = config.my.weathermon;

  mappedProviders = mapAttrsToList (
    name: provider:
    (mkIf provider.enable {
      timers."weathermon-${name}" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = provider.schedule;
          # If somehow computer is down, run once more after it becomes available
          Persistent = true;
          Unit = "weathermon-${name}.service";
        };
      };

      # It's better to have the visibility on network issues by looking into the journal error message.
      services."weathermon-${name}" =
        let
          startScript = pkgs.writeShellScript "weathermon-${name}-start" ''
            curl -s -o ${provider.path}/${name}_$(date +\%Y\%m\%d-\%H\%M) ${provider.url} -A "Mozilla/5.0 (X11; Linux x86_64; rv:141.0) Gecko/20100101 Firefox/141.0"
          '';
        in
        {
          description = "Weather Monitoring Service for ${name}";
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
  ) cfg.providers;

  providerOptions = {
    options = {
      enable = mkEnableOption "Specific Weather Provider";
      path = mkOption {
        type = types.str;
        description = "Path to save data, no trailing slash";
      };
      url = mkOption {
        type = types.str;
        description = "URL to GET";
      };
      schedule = mkOption {
        type = types.str;
        default = "*:0/5"; # Every 5th minutes
        description = "Systemd timer schedule for this provider";
      };
    };
  };
in
{
  options.my.weathermon = {
    enable = mkEnableOption "Weather Monitoring Service";
    providers = mkOption {
      type = with types; attrsOf (submodule providerOptions);
      description = "List of weather providers to use.";
    };
  };

  # Workaround the infinite recursion
  config.systemd = mkIf cfg.enable (mkMerge mappedProviders);
}
