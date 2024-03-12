{
  # The public key of a SSH key used by agenix in x1c7-img.
  # The private key of the same key is in CLEARTEXT as all the content encrypted using this key pair WOULD be accessible by anybody.
  img_pubkey = (builtins.readFile ./raw/img_key_ed25519.pub);

  # The public key of a SSH key used by agenix in x1c7
  # The private key of the same key pair is in ciphertext and encrypted by GPG AES-256 using:
  # gpg -a --cipher-algo AES256 -c ash_ed25519
  # It could be decrypted by using:
  # gpg -o ash_ed25519 -d ash_ed25519.asc
  ash_pubkey = (builtins.readFile ./raw/ash_ed25519.pub);

  # The public key of a SSH key used by agenix for any VPS.
  # This should be used for agenix only as VPS are usually not full-disk encrypted.
  # The existence of such key is more for mitigating risks from making repo public than from VPS provider.
  # The private key is in ciphertext and encrypted using the same scheme as "ash_pubkey".
  vps_pubkey = (builtins.readFile ./raw/vps_ed25519.pub);
}
