let
  keys = import ./keys.nix;
in
{
  "clash_config_img.age".publicKeys = [ keys.img_pubkey ];
  "clash_config_x1c7.age".publicKeys = [ keys.ash_pubkey ];
}
