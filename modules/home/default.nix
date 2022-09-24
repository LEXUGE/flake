{ pkgs, lib, config, ... }:

with lib;

let
  gnomeEnable = config.services.xserver.desktopManager.gnome.enable;
  cfg = config.my.home;
  mkUserConfigs = f: (attrsets.mapAttrs (n: c: (f n c)) cfg);
in
{
  options.my.home = mkOption {
    type = with types;
      attrsOf (submodule {
        options = {
          extraPackages = mkOption {
            type = with types; nullOr (listOf package);
            default = null;
            description =
              "Extra packages to install for user <literal>ash</literal>.";
          };
          emacsPackages = mkOption {
            type = with types; listOf package;
            default = with pkgs; [
              (hunspellWithDicts [ hunspellDicts.en-us hunspellDicts.en-us-large ])
              emacs-all-the-icons-fonts
              ash-emacs-x86_64-linux
            ];
            description = "Packages being installed for Emacs.";
          };
        };
      });
    default = { };
  };

  config.home-manager = {
    users = mkUserConfigs (n: c:
      { lib, ... }:
      let inherit (lib.hm.gvariant) mkTuple;
      in {
        # Use system stateVersion;
        home.stateVersion = config.system.stateVersion;

        # Home-manager settings.
        # User-layer packages
        home.packages = with pkgs;
          (c.emacsPackages ++ optionals (gnomeEnable) [
            ## Apps that must be present in GNOME
            firefox-wayland
            tdesktop
          ]) ++ optionals (c.extraPackages != null) c.extraPackages;

        # Allow fonts to be discovered
        fonts.fontconfig.enable = true;

        # Package settings
        programs = {
          # GnuPG
          gpg = {
            enable = true;
            settings = { throw-keyids = false; };
          };

          # Git
          git = {
            enable = true;
            userName = "Harry Ying";
            userEmail = "lexugeyky@outlook.com";
            signing = {
              signByDefault = true;
              key = "0xAE53B4C2E58EDD45";
            };
            extraConfig = {
              credential = { helper = "store"; };
              pull.ff = "only"; # Use fast-forward only for git pull.
            };
          };

          # zsh
          zsh = {
            enable = true;
            # This would make C-p, C-n act exactly the same as what up/down arrows do.
            initExtra = ''
              bindkey "^P" up-line-or-search
              bindkey "^N" down-line-or-search
            '';
            envExtra = "";
            defaultKeymap = "emacs";
            oh-my-zsh = {
              enable = true;
              theme = "agnoster";
              plugins = [ "git" ];
            };
          };
        };

        # Setting GNOME Dconf settings
        dconf.settings = mkIf (gnomeEnable) {
          # Input sources
          "org/gnome/desktop/input-sources".sources = map mkTuple [
            [ "xkb" "us" ]
            [ "ibus" "libpinyin" ]
            [ "ibus" "typing-booster" ]
          ];
          # Touchpad settings
          "org/gnome/desktop/peripherals/touchpad" = {
            disable-while-typing = false;
            tap-to-click = true;
            two-finger-scrolling-enabled = true;
          };
          # Prefer dark mode
          "org/gnome/desktop/interface".color-scheme = "prefer-dark";
          # Don't suspend on power
          "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type =
            "nothing";
          # Always show logout
          "org/gnome/shell".always-show-log-out = true;
          # Keybindings
          "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          ];
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" =
            {
              binding = "<Super>Return";
              command = "kgx";
              name = "Open Terminal";
            };
          "org/gnome/desktop/wm/keybindings" = {
            close = [ "<Shift><Super>q" ];
            show-desktop = [ "<Super>d" ];
            toggle-fullscreen = [ "<Super>f" ];
          };
          # Favorite apps
          "org/gnome/shell" = {
            favorite-apps = [
              "firefox.desktop"
              "telegramdesktop.desktop"
              "org.gnome.Nautilus.desktop"
              "org.gnome.Terminal.desktop"
              "emacs.desktop"
            ];
          };
        };

        # Handwritten configs
        home.file = {
          ".emacs.d/init.el".source = "${pkgs.ash-emacs-source}/init.el";
          ".emacs.d/elisp/".source = "${pkgs.ash-emacs-source}/elisp";
        };
      });
    useGlobalPkgs = true;
  };
}
