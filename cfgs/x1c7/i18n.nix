{ pkgs, lib, config, ... }: {
  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ libpinyin typing-booster ];
    };
  };
}
