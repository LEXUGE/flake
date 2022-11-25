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

  # activation script that signs grub and related files
  # This is run after the GRUB install
  system.activationScripts.sbsign = {
    text = ''
      sign () {
        if [ -f "$1" ]; then
          while ${pkgs.sbsigntool}/bin/sbattach --remove "$1" &> /dev/null; do :; done
          ${pkgs.sbctl}/bin/sbctl sign "$1"
          ${pkgs.sbsigntool}/bin/sbverify --cert "${config.age.secrets.secureboot_db_cert.path}" "$1"
        fi
      }

      sign "/boot/efi/EFI/BOOT/BOOTX64.EFI"
      sign "/boot/efi/EFI/nixos/fwupdx64.efi"

      for x in /boot/kernels/*-linux-*-bzImage; do
        sign $x
      done
    '';
    # we need decrypted keys to sign images and kernels
    deps = [ "agenix" ];
  };

  boot.loader.grub.extraGrubInstallArgs = [ "--modules=tpm" "--disable-shim-lock" ];
}
