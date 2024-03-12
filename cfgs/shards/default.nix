# HOW TO INSTALL:
# `nixos-anywhere -i ~/ash_ed25519 --extra-files TEMP --flake .#shards root@ip`
# where TEMP should include /persist/secrets/vps_ed25519
# make sure TEMP is of mode 700
#
# HOW TO DEPLOY
# `deploy .#shards --ssh-opts="-i ~/ash_ed25519"`
{ config, lib, pkgs, ... }: {
  imports = [
    ./secrets.nix
    ./hardware.nix
    ./services.nix
    ./disk-config.nix
  ];

  system.stateVersion = "24.05";

  time.timeZone = "Europe/London";

  # Firewall options
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # This is required to push "unsigned" nix store paths. We only allow wheel group to do so to limit the attack surface.
  nix.settings.trusted-users = [ "@wheel" ];

  # Allow passwrodless root for colmena to work
  security.sudo.wheelNeedsPassword = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  boot.initrd.systemd.enable = true;
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "size=1G" "mode=755" ];
  };

  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib"
      "/var/cache"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
    users.ash = {
      directories = [ "persisted" ];
    };
  };

  environment.systemPackages = with pkgs; [ coreutils-full gitMinimal curl ];

  users = {
    # Let users be immutable/declarative
    mutableUsers = false;
    # Note: these are only basic users, users for specific profiles/services, e.g. networking services' pseudo users are declared seperately
    # Note: for portable usages, passwords should be changed here.
    users = {
      root.hashedPassword =
        "$6$EKVU.ASDFD1ehd$HhL4g2ZSAKy7w5hOZPcrzxcd3R3axmx6Ku/xL6lvoGy1kJ1flTpxXEPNO/wxCYaxGQHt2Nt5VsY5VBmWU1dAV/";
      ash = {
        hashedPassword =
          "$6$/DrCzjENUCPZ$3YWcERAWSkLiZYG8YMeyDDo6j8mJ517MZ3GmEplLeF4HVw8125.k2qEsLgNmS1IyHK7VhyaRv7Rd4azsT.nEy.";
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      };
    };
  };
}
