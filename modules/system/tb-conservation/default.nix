{
  lib,
  pkgs,
  config,
  ...
}:

with lib;

let
  cfg = config.my.tb-conservation;
in
{
  options.my.tb-conservation = {
    enable = mkEnableOption "ThinkBook Battery Conservation Mode";
  };

  config = mkIf cfg.enable {
    systemd.services.conservation-mode = {
      enable = true;
      description = "Turn on the ThinkBook power conservation mode for battery health";
      wantedBy = [ "multi-user.target" ];

      unitConfig.RequiresMountsFor = "/sys";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = (
          pkgs.writeShellScript "start_conservation_mode" ''
            echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
          ''
        );
        ExecStop = (
          pkgs.writeShellScript "stop_conservation_mode" ''
            echo 0 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
          ''
        );
      };
    };
  };
}
