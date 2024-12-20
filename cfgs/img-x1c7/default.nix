{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  imports = [
    ./networking.nix
  ];

  config = {
    # To fix home-manager issue
    # https://github.com/nix-community/home-manager/blob/master/modules/misc/version.nix
    system.stateVersion = "23.11";

    boot.kernelPackages = pkgs.linuxPackages_latest;

    # This is a dummy key in ISO image, we shall not worry about its security.
    # Agenix breaks in LiveCD due to https://github.com/ryantm/agenix/issues/165.
    age.identityPaths = [
      (pkgs.writeText "img_key_ed25519" (builtins.readFile ../../secrets/raw/img_key_ed25519))
    ];

    # GPG agent that makes GPG work in LiveCD.
    programs.gnupg.agent.enable = true;

    # ZFS is currently broken on the latest kernel. Since we don't use it, it's fine to disable it.
    boot.supportedFilesystems = lib.mkForce [
      "btrfs"
      "reiserfs"
      "vfat"
      "f2fs"
      "xfs"
      "ntfs"
      "cifs"
    ];

    # Set internationalisation properties.
    console = {
      font = "Lat2-Terminus16";
      useXkbConfig = true;
    };
    i18n = {
      defaultLocale = "en_US.UTF-8";
      inputMethod = {
        enable = true;
        type = "ibus";
        ibus.engines = with pkgs.ibus-engines; [
          libpinyin
          typing-booster
        ];
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
    };
    services.displayManager.autoLogin = {
      enable = true;
      user = "nixos";
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
        firefox
        htop
        dnsutils
        smartmontools
      ];
      extraDconf =
        let
          hm = inputs.home-manager.lib.hm;
        in
        {
          "org/gnome/desktop/interface"."scaling-factor" = hm.gvariant.mkUint32 2;
        };
    };

    # This is a LiveCD, please don't enable disk config in NixOS.
    disko.enableConfig = false;

    environment.systemPackages =
      with pkgs;
      let
        create-disko-pkg =
          name: path:
          (runCommandLocal "disko-${name}" { } ''
            mkdir -p $out/bin
            install ${path} $out/bin/disko-${name}
          '');
      in
      [
        (writeShellScriptBin "install-script" (builtins.readFile ./install.sh))

        (create-disko-pkg "main" config.system.build.diskoScript)
        (create-disko-pkg "format" config.system.build.formatScript)
        (create-disko-pkg "mount" config.system.build.mountScript)
      ];

    users.users.nixos.shell = pkgs.zsh;
    programs.zsh.enable = true;
  };
}
