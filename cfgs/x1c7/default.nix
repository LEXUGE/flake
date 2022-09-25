{ config, pkgs, ... }: {
  imports = [
    ./boot.nix
    ./hardware.nix
    ./networking.nix
    ./i18n.nix
    ./services.nix
  ];

  config = {
    my.gnome-desktop.enable = true;
    my.base = {
      enable = true;
      hostname = "x1c7";
    };
    my.home.ash.extraPackages = with pkgs; [
      firefox-wayland
      tdesktop
      htop
      qbittorrent
      zoom-us
      thunderbird-bin
      pavucontrol
      dnsperf
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
          { directory = ".gnupg"; mode = "0700"; }
          { directory = ".ssh"; mode = "0700"; }
          { directory = ".local/share/keyrings"; mode = "0700"; }
          ".thunderbird"
        ];
      };
    };

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
          extraGroups = [ "wheel" "networkmanager" ];
        };
      };
    };

    system.stateVersion = "22.11";
  };
}
