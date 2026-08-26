{
  options,
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
        # 5 # Can measure configuration of boot loaders; includes the GPT Partition Table
        7 # Secure Boot state (full contents of PK/KEK/db + certificates used to validate each boot application)

        # Not very useful as SecureBoot already ensures that we are booting trustworthy kernels.
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
    in
    {
      my.gnome-desktop.enable = true;
      my.base = {
        enable = true;
        hostname = "tb14";
      };

      # Restore the persisted standalone Home Manager generation on every boot.
      # `.local` is persisted below, including `.local/state/nix/profiles`.
      nix.settings.use-xdg-base-directories = true;
      rehomify = {
        enable = true;
        users = [ "ash" ];
      };

      programs.nix-ld = {
        enable = true;
        libraries =
          options.programs.nix-ld.libraries.default
          ++ (with pkgs; [
            glib # libglib-2.0.so.0
            numactl
          ]);
      };

      # Fonts
      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
      ];

      environment.systemPackages = with pkgs; [
        kdiskmark
        bless
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
          # if machine-id goes "uninitialized", try first stop the persist-machine-id service and then remove the /persist/etc/machine-id then restart
          "/etc/machine-id"
          "/etc/persisted-timezone"
        ];
        users.ash = {
          files = [
            ".config/monitors.xml"
            ".ideavimrc"
          ];
          directories = [
            ".lmstudio"
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
            ".config/Zulip"
            ".config/Signal"
            ".config/google-chrome"
            ".config/JetBrains"
            ".codex"
            ".pi"
            ".cargo"
            ".tor project"
            ".Wolfram"
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
              "video"
              "render"
              "kvm"
            ];
          };
        };
      };

      system.stateVersion = "22.11";
    };
}
