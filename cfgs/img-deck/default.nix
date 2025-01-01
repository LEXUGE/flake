{
  inputs,
  pkgs,
  ...
}:
{
  my.image-base = {
    enable = true;
    target = "deck";
  };

  # Needed for boot! Otherwise the initrd couldn't mount the root on hub.
  boot.initrd.availableKernelModules = [ "hub" ];

  my.home.nixos = {
    extraDconf = {
      # Show screen keyboard
      "org/gnome/desktop/a11y/applications".screen-keyboard-enabled = true;
    };
  };
  my.steamdeck = {
    enable = true;
  };
}
