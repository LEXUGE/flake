{ pkgs, lib, config, ... }: {
  # v2ray config
  age.secrets.v2ray_config = {
    file = ../../secrets/v2ray_shards.age;
    # Seems like we are unable to get pass the DynamicsUser issue
    mode = "444";
  };

  # secret key decrypted on install
  age.identityPaths = [ "/persist/secrets/vps_ed25519" ];
}
