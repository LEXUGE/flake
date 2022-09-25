let
  keys = import ./keys.nix;
in
{
  "clash_config_img.age".publicKeys = [ keys.img_key ];
}
