{ config, pkgs, ... }: {
  imports = [
    ./boot.nix
    ./networking.nix
    ./i18n.nix
    ./services.nix
    ./security.nix
  ];

  config = {
    disko.devices = (import ./disk.nix { });

    my.steamdeck.enable = true;
    my.gnome-desktop.enable = true;
    my.base = {
      enable = true;
      hostname = "deck";
    };

    # home-manager.users.ash.systemd.user.sessionVariables = config.home-manager.users.ash.home.sessionVariables;
    my.home.ash.extraPackages = with pkgs; [
      protonup
      minecraft
      tor-browser-bundle-bin
      sbctl
      firefox-wayland
      tdesktop
      htop
      dnsutils
      smartmontools
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
          "$6$1OTuo6NhaigjwWOa$XDYQv8oqvsVdOc8hW3d96O5hcqD0248PVUBXyXLmKhd9p/ylCWJjjfW2ge6drWk1WAZwnBRdJrkY4tKWasUgd/";
        ash = {
          hashedPassword =
            "$6$5uqzmikO2CCpZYUU$gzu6r4Kz9Eik5tzZ.sXL2G/R1Bb8No/zLV5tGCqnDG5cYrfbAgXtNWX.JCrX4yFCQ714cSWYUCBSsI2eWDZiQ1";
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

    system.stateVersion = "23.05";
  };
}
