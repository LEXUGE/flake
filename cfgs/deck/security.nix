{ pkgs, lib, config, ... }: {
  # sbctl database files
  age.secrets = {
    secureboot_guid = {
      file = ../../secrets/secureboot/GUID.age;
      path = "/etc/secureboot/GUID";
      mode = "444";
      owner = "root";
    };

    # secureboot db
    secureboot_db_key = {
      file = ../../secrets/secureboot/db_key.age;
      path = "/etc/secureboot/keys/db/db.key";
      mode = "400";
      owner = "root";
    };
    secureboot_db_cert = {
      file = ../../secrets/secureboot/db_cert.age;
      path = "/etc/secureboot/keys/db/db.pem";
      mode = "400";
      owner = "root";
    };

    # secureboot KEK
    secureboot_kek_key = {
      file = ../../secrets/secureboot/KEK_key.age;
      path = "/etc/secureboot/keys/KEK/KEK.key";
      mode = "400";
      owner = "root";
    };

    secureboot_kek_cert = {
      file = ../../secrets/secureboot/KEK_cert.age;
      path = "/etc/secureboot/keys/KEK/KEK.pem";
      mode = "400";
      owner = "root";
    };

    # secureboot PK
    secureboot_pk_key = {
      file = ../../secrets/secureboot/PK_key.age;
      path = "/etc/secureboot/keys/PK/PK.key";
      mode = "400";
      owner = "root";
    };

    secureboot_pk_cert = {
      file = ../../secrets/secureboot/PK_cert.age;
      path = "/etc/secureboot/keys/PK/PK.pem";
      mode = "400";
      owner = "root";
    };
  };

  # Clash config
  age.secrets.clash_config = {
    file = ../../secrets/clash_config_x1c7.age;
    mode = "700";
    owner = config.my.clash.clashUserName;
  };

  # secret key decrypted on install
  age.identityPaths = [ "/persist/secrets/ash_ed25519" ];
}
