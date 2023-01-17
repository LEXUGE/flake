{ config, lib, pkgs, ... }: with lib;
{
  imports = [
    ./networking.nix
  ];

  config = {
    age.secrets.clash_config = {
      file = ../../secrets/clash_config_img.age;
      mode = "700";
      owner = config.my.clash.clashUserName;
    };
    # This is a dummy key in ISO image, we shall not worry about its security.
    age.identityPaths = [ ../../secrets/raw/img_key_ed25519 ];

    # GPG agent that makes GPG work in LiveCD.
    programs.gnupg.agent.enable = true;

    # ZFS is currently broken on the latest kernel. Since we don't use it, it's fine to disable it.
    boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

    # Set internationalisation properties.
    console = {
      font = "Lat2-Terminus16";
      useXkbConfig = true;
    };
    i18n = {
      defaultLocale = "en_US.UTF-8";
      inputMethod = {
        enabled = "ibus";
        ibus.engines = with pkgs.ibus-engines; [ libpinyin typing-booster ];
      };
    };

    # Fonts
    fonts.fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      fira-code
      fira-code-symbols
    ];

    isoImage.edition = "gnome";

    # Whitelist wheel users to do anything
    # This is useful for things like pkexec
    #
    # WARNING: this is dangerous for systems
    # outside the installation-cd and shouldn't
    # be used anywhere else.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    networking.wireless.enable = mkForce false;

    services.xserver.displayManager = {
      gdm = {
        # autoSuspend makes the machine automatically suspend after inactivity.
        # It's possible someone could/try to ssh'd into the machine and obviously
        # have issues because it's inactive.
        # See:
        # * https://github.com/NixOS/nixpkgs/pull/63790
        # * https://gitlab.gnome.org/GNOME/gnome-control-center/issues/22
        autoSuspend = false;
      };
      autoLogin = {
        enable = true;
        user = "nixos";
      };
    };

    my.gnome-desktop = {
      enable = true;
      extraExcludePackages = [ pkgs.orca ];
    };
    my.base = {
      enable = true;
      hostname = "img";
    };
    my.home.nixos = {
      extraPackages = with pkgs; [
        firefox-wayland
        htop
        dnsutils
        smartmontools
      ]; # Show screen keyboard
      extraDconf = {
        "org/gnome/desktop/a11y/applications".screen-keyboard-enabled = true;
      };
    };
    my.steamdeck = {
      enable = true;
      opensdUser = "nixos";
    };

    disko.devices = (import ./../deck/disk.nix { });
    # This is a LiveCD, please don't enable disk config in NixOS.
    disko.enableConfig = false;

    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "install-script"
        (builtins.readFile ./install.sh))

      # Create and mount, `disko`
      (writeShellScriptBin "disko"
        (builtins.readFile config.system.build.disko))
      # Create, `disko-create`
      (writeShellScriptBin "disko-create"
        (builtins.readFile config.system.build.formatScript))
      # Mount, `disko-mount`
      (writeShellScriptBin "disko-mount"
        (builtins.readFile config.system.build.mountScript))
    ];

    users.users.nixos = {
      shell = pkgs.zsh;
    };
  };
}
