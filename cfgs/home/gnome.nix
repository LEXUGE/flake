{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.hm.gvariant) mkTuple;

  # GTK 3 applications do not consistently obey the dark-mode gsetting.
  gtkSettings = pkgs.writeText "gtk-settings.ini" ''
    [Settings]
    gtk-application-prefer-dark-theme = true
  '';
in
{
  dconf.settings = {
    "org/gnome/desktop/input-sources".sources = map mkTuple [
      [
        "xkb"
        "us"
      ]
      [
        "ibus"
        "libpinyin"
      ]
      [
        "ibus"
        "typing-booster"
      ]
    ];
    "com/github/libpinyin/ibus-libpinyin/libpinyin" = {
      english-candidate = false;
      comma-period-page = true;
      minus-equal-page = true;
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      disable-while-typing = false;
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };
    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      edge-tiling = true;
    };
    "org/gnome/shell" = {
      welcome-dialog-last-shown-version = "9999999999";
      always-show-log-out = true;
      favorite-apps = lib.lists.flatten [
        (lib.optional (builtins.elem pkgs.firefox config.home.packages) "firefox.desktop")
        (lib.optional (builtins.elem pkgs.telegram-desktop config.home.packages) "org.telegram.desktop.desktop")
        "org.gnome.Nautilus.desktop"
        "org.gnome.Terminal.desktop"
      ];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      show-battery-percentage = true;
    };
    "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
    "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
      "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    ];
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "kgx";
      name = "Open Terminal";
    };
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Shift><Super>q" ];
      show-desktop = [ "<Super>d" ];
      toggle-fullscreen = [ "<Super>f" ];
    };
    "org/gnome/system/location".enabled = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style = {
      package = pkgs.adwaita-qt;
      name = "adwaita-dark";
    };
  };

  home.file.".config/gtk-3.0/settings.ini".source = gtkSettings;
}
