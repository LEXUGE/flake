{ pkgs, lib, config, ... }: {
  age.secrets.clash_config = {
    file = ../../secrets/clash_config_x1c7.age;
    mode = "700";
    owner = config.my.clash.clashUserName;
  };

  # secret key decrypted on install
  age.identityPaths = [ "/persist/secrets/ash_ed25519" ];
}
