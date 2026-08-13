{
  inputs,
  pkgs,
  ...
}:
{
  my.image-base = {
    enable = true;
    target = "tb14";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  home-manager.users.nixos.dconf.settings."org/gnome/desktop/interface"."scaling-factor" =
    inputs.home-manager.lib.hm.gvariant.mkUint32 2;
}
