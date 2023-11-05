# WARNING: everything encrypted with img_pubkey is essentially in cleartext!
# NEVER sign anything with img_pubkey together

let
  keys = import ./keys.nix;
in
{
  "dae_config_img.age".publicKeys = [ keys.img_pubkey ];

  "dae_config.age".publicKeys = [ keys.ash_pubkey ];

  "secureboot/db_key.age".publicKeys = [ keys.ash_pubkey ];
  "secureboot/db_cert.age".publicKeys = [ keys.ash_pubkey ];
  "secureboot/KEK_key.age".publicKeys = [ keys.ash_pubkey ];
  "secureboot/KEK_cert.age".publicKeys = [ keys.ash_pubkey ];
  "secureboot/PK_key.age".publicKeys = [ keys.ash_pubkey ];
  "secureboot/PK_cert.age".publicKeys = [ keys.ash_pubkey ];
  "secureboot/GUID.age".publicKeys = [ keys.ash_pubkey ];
}
