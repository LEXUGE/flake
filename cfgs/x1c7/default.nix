{ config, pkgs, ... }: {
  imports = [
    ./secureboot.nix
    ./boot.nix
    ./hardware.nix
    ./networking.nix
    ./i18n.nix
    ./services.nix
    ./security.nix
  ];

  config = {
    my.gnome-desktop.enable = true;
    my.base = {
      enable = true;
      hostname = "x1c7";
    };

    # home-manager.users.ash.systemd.user.sessionVariables = config.home-manager.users.ash.home.sessionVariables;
    my.home.ash.extraPackages = with pkgs; [
      minecraft
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
      dnsutils
      smartmontools
      # Steam scaling seems to be broken, doing it manually
      (runCommand "steam-hidpi"
        {
          nativeBuildInputs = [ makeWrapper ];
        } ''
        mkdir -p $out/bin
        makeWrapper ${steam}/bin/steam $out/bin/steam --set GDK_SCALE 2
        cp -r ${steam}/share $out/share/
      '')
    ];

    # Fonts
    fonts.fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      fira-code
      fira-code-symbols
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
      ];
      users.ash = {
        directories = [
          "Desktop"
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Videos"
          ".cache"
          ".local"
          ".mozilla"
          ".thunderbird"
          ".config/qBittorrent"
          # Both git-credentials and zsh_hist_dir doesn't seem to play well with impermanence
          { directory = ".git_creds_dir"; mode = "0700"; }
          { directory = ".zsh_hist_dir"; mode = "0700"; }
          { directory = ".gnupg"; mode = "0700"; }
          { directory = ".ssh"; mode = "0700"; }
          { directory = ".local/share/keyrings"; mode = "0700"; }
        ];
      };
    };

    # Otherwise tmp will be a normal folder created on boot, which is capped by total size of /
    boot.tmpOnTmpfs = true;
    boot.tmpOnTmpfsSize = "65%";

    users = {
      mutableUsers = false;
      users = {
        root.hashedPassword =
          "$6$TqNkihvO4K$x.qSUVbLQ9.IfAc9tOQawDzVdHJtQIcKrJpBCBR.wMuQ8qfbbbm9bN7JNMgneYnNPzAi2k9qXk0klhTlRgGnk0";
        ash = {
          hashedPassword =
            "$6$FAs.ZfxAkhAK0ted$/aHwa39iJ6wsZDCxoJVjedhfPZ0XlmgKcxkgxGDE.hw3JlCjPHmauXmQAZUlF8TTUGgxiOJZcbYSPsW.QBH5F.";
          shell = pkgs.zsh;
          isNormalUser = true;
          # wheel - sudo
          # networkmanager - manage network
          # video - light control
          # libvirtd - virtual manager controls.
          # docker - Docker control
          # tss - TPM2 control
          extraGroups = [ "wheel" "networkmanager" "wireshark" "tss" ];
        };
      };
    };

    system.stateVersion = "22.11";
  };
}
