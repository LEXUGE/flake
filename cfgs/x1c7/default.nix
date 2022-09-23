{ config, pkgs, ... }: {
  imports = [
    ./boot.nix
    ./hardware.nix
    ./networking.nix
  ];

  config = {
    my.gnome-desktop.enable = true;
    my.base = {
      enable = true;
      hostname = "x1c7";
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
  };
}
