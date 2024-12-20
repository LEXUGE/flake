{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./boot.nix
    ./networking.nix
    ./i18n.nix
    ./services.nix
    ./security.nix
  ];

  config =
    let # To avoid having to reseal on each kernel/initrd update
      # (must have secure boot and use Unified Kernel Image)
      pcrBanks = [
        0 # Core System Firmware executable code
        # 2 # Extended or pluggable executable code (e.g., Option ROMs)
        7 # Secure Boot state (full contents of PK/KEK/db + certificates used to validate each boot application)
        # 12 # systemd-stub: Overridden kernel command line
        # 13 # systemd-stub: System Extensions
      ];

      root = config.boot.initrd.luks.devices."cryptroot".device;
      swap = config.boot.initrd.luks.devices."cryptswap".device;

      bless =
        let
          pcrBankList = builtins.concatStringsSep "+" (map (x: builtins.toString x) pcrBanks);
        in
        pkgs.writeShellScriptBin "bless-current-pcr" ''
          set -euo pipefail

          /run/current-system/sw/bin/systemd-cryptenroll --wipe-slot=tpm2 ${root}
          /run/current-system/sw/bin/systemd-cryptenroll --wipe-slot=tpm2 ${swap}
          /run/current-system/sw/bin/systemd-cryptenroll --tpm2-pcrs=${pcrBankList} --tpm2-device=auto ${root}
          /run/current-system/sw/bin/systemd-cryptenroll --tpm2-pcrs=${pcrBankList} --tpm2-device=auto ${swap}

          echo "Blessed current PCRs"
        '';

      startSingBox = pkgs.writeShellScriptBin "start-sing-box" ''
        ${pkgs.systemd}/bin/systemctl restart singb-box
      '';

      stopSingBox = pkgs.writeShellScriptBin "stop-sing-box" ''
        ${pkgs.systemd}/bin/systemctl stop singb-box
      '';
    in
    {
      # Remove once https://github.com/NixOS/nixpkgs/pull/210896 is merged into unstable
      # systemd.package = pkgs.systemd.overrideAttrs (attrs: {
      #   patches = attrs.patches ++ [ ../../misc/patches/systemd-tpm2-name-check.patch ];
      # });
      # boot.initrd.systemd.package = pkgs.systemdStage1.overrideAttrs (attrs: {
      #   patches = attrs.patches ++ [ ../../misc/patches/systemd-tpm2-name-check.patch ];
      # });

      # We are auto login user.
      security.sudo.wheelNeedsPassword = lib.mkForce true;

      my.gnome-desktop = {
        enable = true;
        enableDisplayManager = false;
      };
      my.base = {
        enable = true;
        hostname = "deck";
      };

      # Allow users in wheel to control sing-box without passwords.
      security.sudo.extraRules = [
        {
          groups = [ "whell" ];
          commands = [
            {
              command = "${startSingBox}";
              options = [
                "NOPASSWD"
                "SETENV"
              ];
            }
            {
              command = "${stopSingBox}";
              options = [
                "NOPASSWD"
                "SETENV"
              ];
            }
          ];
        }
      ];

      my.home.ash = {
        extraPackages = with pkgs; [
          # minecraft
          tor-browser-bundle-bin
          sbctl
          firefox
          htop
          dnsutils
          smartmontools
          bless
          steamdeck-firmware

          # Setup the necessary game apps needed in deck user
          # yuzu
          steam-rom-manager
          steam
          protonup
          lutris

          # reload/suspend sing-box
          (makeDesktopItem {
            name = "startSingBox";
            desktopName = "sing-box start";
            exec = "${startSingBox}";
            terminal = true;
          })

          (makeDesktopItem {
            name = "stopSingBox";
            desktopName = "sing-box stop";
            exec = "${stopSingBox}";
            terminal = true;
          })

        ];
        # Show screen keyboard
        extraDconf = {
          "org/gnome/desktop/a11y/applications".screen-keyboard-enabled = true;
        };

        # Extra files
        extraFiles = {
          ".config/steam-rom-manager/userData/userConfigurations.json".source =
            ../../misc/blobs/steam-rom-manager/userConfigurations.json;
          ".config/yuzu/qt-config.ini".source = ../../misc/blobs/yuzu/qt-config.ini;
        };
      };

      # Steamdeck config
      my.steamdeck = {
        enable = true;
        steam.enable = true;
        steam.user = "ash";
      };

      # Fonts
      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
        # needed by steam to display CJK fonts
        wqy_zenhei
      ];

      # jovian.steam.environment = {
      #   # Add Proton-GE
      #   STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge}";
      # };

      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/var/log"
          "/var/lib"
          "/var/cache"
          "/etc/NetworkManager/system-connections"
        ];
        files = [
          "/etc/machine-id"
          "/etc/persisted-timezone"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
        ];
        users = {
          ash = {
            directories = [
              "Documents"

              # Keep games
              ".local"
              "Games"
              ".steam"
              ".config/yuzu"
              ".config/lutris"
              ".config/steam-rom-manager/userData"

              # Both git-credentials and zsh_hist_dir doesn't seem to play well with impermanence
              # NO sensitive task shall be carried out!
              # { directory = ".git_creds_dir"; mode = "0700"; }
              {
                directory = ".zsh_hist_dir";
                mode = "0700";
              }
              # { directory = ".gnupg"; mode = "0700"; }
              # { directory = ".ssh"; mode = "0700"; }
              # { directory = ".local/share/keyrings"; mode = "0700"; }
            ];
          };
        };
      };

      users = {
        mutableUsers = false;
        users = {
          root.hashedPassword = "$6$oNsoXzCopc6uxli4$vthBqdTNXtq8MWlWRHRGe6QZUMb7CtPWaTdXSOKszeTAtmjG5zE/JPd7F668VTiuOUtpiy1oy061N0LlxjtHD1";
          ash = {
            hashedPassword = "$y$j9T$yLdLVVEQoolJR9LNMYGl30$dNnh67D78jLz/YR9YXSR3i8efYd0QmI2ezo2h5v2W78";
            shell = pkgs.zsh;
            isNormalUser = true;
            # wheel - sudo
            # networkmanager - manage network
            # video - light control
            # libvirtd - virtual manager controls.
            # docker - Docker control
            extraGroups = [
              "wheel"
              "networkmanager"
            ];
          };
        };
      };

      system.stateVersion = "23.05";
    };
}
