{
  pkgs,
  lib,
  config,
  ...
}:

with lib;

let
  gnomeEnable = config.services.xserver.desktopManager.gnome.enable;
  # Gtk3 applications don't obey dark mode settings in gsettings, so let's do it manually.
  gtkSettings = pkgs.writeText "gtk-settings.ini" ''
    [Settings]
    gtk-application-prefer-dark-theme = true
  '';
  cfg = config.my.home;
  mkUserConfigs = f: (attrsets.mapAttrs (n: c: (f n c)) cfg);
in
{
  options.my.home = mkOption {
    type =
      with types;
      attrsOf (submodule {
        options = {
          extraPackages = mkOption {
            type = with types; nullOr (listOf package);
            default = null;
            description = "Extra packages to install for user <literal>ash</literal>.";
          };

          extraDconf = mkOption {
            default = { };
            description = "Extra dconf settings to specify";
          };

          extraFiles = mkOption {
            default = { };
            description = "Extra files to put in declaratively under the home dir";
          };

          emacsPackages = mkOption {
            type = with types; listOf package;
            default = with pkgs; [
              (hunspellWithDicts [
                hunspellDicts.en-us
                hunspellDicts.en-us-large
              ])
              emacs-all-the-icons-fonts
              ash-emacs
            ];
            description = "Packages being installed for Emacs.";
          };
        };
      });
    default = { };
  };

  config.home-manager = {
    users = mkMerge [
      (mkUserConfigs (
        n: c:
        { lib, ... }:
        let
          inherit (lib.hm.gvariant) mkTuple;
        in
        rec {
          # Use system stateVersion;
          home.stateVersion = config.system.stateVersion;

          # Home-manager settings.
          # User-layer packages
          home.packages =
            with pkgs;
            # c.emacsPackages ++ optionals (c.extraPackages != null) c.extraPackages ++ [ pkgs.nvim ];
            optionals (c.extraPackages != null) c.extraPackages ++ [ pkgs.nvim ];

          # Set default editor
          home.sessionVariables = {
            EDITOR = "nvim";
          };

          # Allow fonts to be discovered
          fonts.fontconfig.enable = true;

          # Set default browser
          xdg.mimeApps = {
            enable = true;

            defaultApplications = {
              "text/html" = "torbrowser.desktop";
              "text/xml" = "torbrowser.desktop";
              "application/xhtml+xml" = "torbrowser.desktop";
              "x-scheme-handler/http" = "torbrowser.desktop";
              "x-scheme-handler/https" = "torbrowser.desktop";
            };
          };

          # Package settings
          programs = {
            # Per directory auto env loading
            direnv = {
              enable = true;
              # Hook up the ZSH profile
              enableZshIntegration = true;
              nix-direnv.enable = true;
            };

            # GnuPG
            gpg = {
              enable = true;
              settings = {
                throw-keyids = false;
              };
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
                # To make sure Git don't complain about impermanence's bind mount.
                credential = {
                  helper = "store --file=\"$HOME/.git_creds_dir/.git-credentials\"";
                };
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
              history = {
                # zsh seems to replace the .zsh_history file everytime which is not great with impermanence
                # we create a folder for it to play within.
                path = "$HOME/.zsh_hist_dir/.zsh_history";
              };
            };
          };

          # Setting GNOME Dconf settings
          dconf.settings = mkIf (gnomeEnable) (
            recursiveUpdate {
              # Input sources
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
                # Don't suggest English words
                english-candidate = false;
                # Use comma and period to flip pages
                comma-period-page = true;
                # Don't use minus or equal to flip pages
                minus-equal-page = true;
              };
              # Touchpad settings
              "org/gnome/desktop/peripherals/touchpad" = {
                disable-while-typing = false;
                tap-to-click = true;
                two-finger-scrolling-enabled = true;
              };
              "org/gnome/mutter" = {
                # Enable dynamic workspacing
                dynamic-workspaces = true;
                # Drag to edge tiling
                edge-tiling = true;
              };
              # Don't show welcome-dialog
              "org/gnome/shell".welcome-dialog-last-shown-version = "9999999999";
              # Prefer dark mode
              "org/gnome/desktop/interface".color-scheme = "prefer-dark";
              # Don't suspend on power
              "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
              # Always show logout
              "org/gnome/shell".always-show-log-out = true;
              # Keybindings
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
              # Favorite apps
              "org/gnome/shell" = {
                favorite-apps = lists.flatten [
                  (if (builtins.elem pkgs.firefox-wayland home.packages) then [ "firefox.desktop" ] else [ ])
                  (if (builtins.elem pkgs.tdesktop home.packages) then [ "org.telegram.desktop.desktop" ] else [ ])
                  "org.gnome.Nautilus.desktop"
                  "org.gnome.Terminal.desktop"
                  # "emacs.desktop"
                ];
              };
              # Timezone and location
              # "org/gnome/desktop/datetime".automatic-timezone = true;
              "org/gnome/system/location".enabled = true;
              # Show battery percentage
              "org/gnome/desktop/interface" = {
                show-battery-percentage = true;
              };
            } c.extraDconf
          );

          # Configure uniform UI for QT apps.
          qt = {
            enable = true;
            platformTheme.name = "adwaita";
            style = {
              package = pkgs.adwaita-qt;
              name = "adwaita-dark";
            };
          };

          # Handwritten configs
          home.file = (
            {
              ".config/gtk-3.0/settings.ini".source = gtkSettings;
              # ".emacs.d/init.el".source = "${pkgs.ash-emacs-source}/init.el";
              # ".emacs.d/elisp/".source = "${pkgs.ash-emacs-source}/elisp";
            }
            // c.extraFiles
          );
        }
      ))

      (mkUserConfigs (
        n: c: {
          # GNOME and other wayland DEs use systemd sessionvariables to launch GUI apps. Therefore, it's necessary to set it.
          systemd.user.sessionVariables = config.home-manager.users.${n}.home.sessionVariables;
        }
      ))
    ];
    useGlobalPkgs = true;
  };
}
