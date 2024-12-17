{
  lib,
  pkgs,
  config,
  ...
}:

with lib;

let
  cfg = config.my.timezone;
in
{
  options.my.timezone = {
    enable = mkEnableOption "Imperative Persisted Timezone";
    path = mkOption {
      type = types.str;
      description = "Path to file whose content is the timezone string like `Europe/London`";
    };
  };

  config = mkIf cfg.enable {
    # Set timezone manually using our custom systemd service.
    time.timeZone = null;
    systemd.services.activate_persist_timezone = {
      description = "activate persisted timezone";
      # From `man systemd.special`:
      # netowrk-pre.target: This passive target unit may be pulled in by services that want to run before any network is set up
      wantedBy = [
        "multi-user.target"
        "network-pre.target"
      ];

      serviceConfig = {
        Type = "oneshot";
      };
      # Set timezone based on the content of /etc/persisted-timezone whose content is a string like `Europe/London`.
      # We do this shenanigan to workaround the systemd issue and impermanence issue.
      # https://github.com/nix-community/impermanence/issues/153
      script = "${pkgs.systemd}/bin/timedatectl set-timezone \"$(< ${cfg.path})\"";
    };
  };
}
