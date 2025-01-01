{
  inputs,
  pkgs,
  ...
}:
{
  my.image-base = {
    enable = true;
    target = "x1c7";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  my.home.nixos = {
    extraDconf =
      let
        hm = inputs.home-manager.lib.hm;
      in
      {
        "org/gnome/desktop/interface"."scaling-factor" = hm.gvariant.mkUint32 2;
      };
  };
}
