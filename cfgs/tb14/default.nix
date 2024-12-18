{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./boot.nix
    ./hardware.nix
    ./networking.nix
    ./i18n.nix
    ./services.nix
    ./security.nix
  ];

  config =
    let
      # To avoid having to reseal on each kernel/initrd update
      # (must have secure boot and use Unified Kernel Image)
      # https://wiki.archlinux.org/title/Trusted_Platform_Module#Accessing_PCR_registers
      pcrBanks = [
        0 # Core System Firmware executable code
        1 # UEFI Settings
        2 # Extended or pluggable executable code (e.g., Option ROMs)
        3 # Boot Device selection
        # 4 # Measures the boot manager and the devices that the firmware tried to boot from
        5 # Can measure configuration of boot loaders; includes the GPT Partition Table
        7 # Secure Boot state (full contents of PK/KEK/db + certificates used to validate each boot application)

        # Not very useful as SecureBoot already ensures that we are booting trustworthy kernels.
        # WARN: Still could be dangerous as Microsoft key is present and someone could boot Ubuntu and decrypt the disk.
        # 9 # Hash of the initrd and EFI Load Options
        # 11 # Hash of the unified kernel image
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

      hm = inputs.home-manager.lib.hm;
    in
    {
      my.gnome-desktop.enable = true;
      my.base = {
        enable = true;
        hostname = "tb14";
      };

      # home-manager.users.ash.systemd.user.sessionVariables = config.home-manager.users.ash.home.sessionVariables;
      my.home.ash = {
        extraPackages = with pkgs; [
          zulip
          # minecraft
          tor-browser-bundle-bin
          tpm2-tools
          sbctl
          firefox-wayland
          tdesktop
          htop
          qbittorrent
          zoom-us
          thunderbird-bin
          pavucontrol
          dnsperf
          bless
          dnsutils
          smartmontools
          # Steam scaling seems to be broken, doing it manually
          # (runCommand "steam-hidpi"
          #   {
          #     nativeBuildInputs = [ makeWrapper ];
          #   } ''
          #   mkdir -p $out/bin
          #   makeWrapper ${steam}/bin/steam $out/bin/steam --set GDK_SCALE 2
          #   cp -r ${steam}/share $out/share/
          # '')
          steam
          # obsidian
          # We fix installer version so don't get updated automatically when Wolfram releases new version
          (import inputs.nixpkgs-mathematica {
            system = pkgs.system;
            config.allowUnfree = true;
            overlays = [
              (final: prev: {
                # Patch mathematica to solve "libdbus not found" error.
                # Also pin it to a specific commit to prevent from rebuilding.
                mathematica_13_3_1 =
                  (prev.mathematica.overrideAttrs (
                    _: prevAttrs: {
                      wrapProgramFlags = prevAttrs.wrapProgramFlags ++ [
                        "--prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath [ prev.dbus.lib ]}"
                      ];
                    }
                  )).override
                    {
                      version = "13.3.1";
                    };
              })
            ];
          }).mathematica_13_3_1
          coyim
          zotero
        ];
        extraDconf = {
          "org/gnome/desktop/interface"."scaling-factor" = hm.gvariant.mkUint32 2;
        };
      };

      # Fonts
      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
      ];

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
        ];
        users.ash = {
          files = [
            ".config/monitors.xml"
          ];
          directories = [
            "Desktop"
            "Documents"
            "Downloads"
            "Music"
            "Pictures"
            "Videos"
            "Zotero"
            ".zotero"
            ".cache"
            ".local"
            ".mozilla"
            ".thunderbird"
            ".config/qBittorrent"
            ".config/coyim"
            ".config/Zulip"
            ".julia"
            ".Mathematica"
            "org-files"
            # Both git-credentials and zsh_hist_dir doesn't seem to play well with impermanence
            {
              directory = ".git_creds_dir";
              mode = "0700";
            }
            {
              directory = ".zsh_hist_dir";
              mode = "0700";
            }
            {
              directory = ".gnupg";
              mode = "0700";
            }
            {
              directory = ".ssh";
              mode = "0700";
            }
            {
              directory = ".local/share/keyrings";
              mode = "0700";
            }
          ];
        };
      };

      users = {
        mutableUsers = false;
        users = {
          root.hashedPassword = "$6$TqNkihvO4K$x.qSUVbLQ9.IfAc9tOQawDzVdHJtQIcKrJpBCBR.wMuQ8qfbbbm9bN7JNMgneYnNPzAi2k9qXk0klhTlRgGnk0";
          ash = {
            hashedPassword = "$6$FAs.ZfxAkhAK0ted$/aHwa39iJ6wsZDCxoJVjedhfPZ0XlmgKcxkgxGDE.hw3JlCjPHmauXmQAZUlF8TTUGgxiOJZcbYSPsW.QBH5F.";
            shell = pkgs.zsh;
            isNormalUser = true;
            # wheel - sudo
            # networkmanager - manage network
            # video - light control
            # libvirtd - virtual manager controls.
            # docker - Docker control
            # tss - TPM2 control
            extraGroups = [
              "wheel"
              "networkmanager"
              "wireshark"
              "tss"
            ];
          };
        };
      };

      system.stateVersion = "22.11";
    };
}
