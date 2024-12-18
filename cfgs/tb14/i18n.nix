{
  pkgs,
  lib,
  config,
  ...
}:
{
  my.timezone = {
    enable = true;
    path = "/etc/persisted-timezone";
  };

  # Select internationalisation properties.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enable = true;
      type = "ibus";
      ibus.engines = with pkgs.ibus-engines; [
        libpinyin
        typing-booster
      ];
    };
  };
}
