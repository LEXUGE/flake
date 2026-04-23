# System Logs
This is a log file for incidents/changes occurred during upgrading/restructuring the configuration.

## 2025-03-01

We reinstalled config on the `shards`.

Installation is performed by flashing the disko image via a **rescue ISO** to the hard drive.

The disko image was created using
`nix build .\#imgs.shards-script`
And
`sudo ./result --post-format-files /home/ash/TMP/persist/secrets/vps_ed25519 /persist/secrets/vps_ed25519`

This will result in a `*.raw` file in the folder.

Then spin up the sshd in the rescue disk and
`cat main.raw | ssh -i ash_ed25519 root@IP "dd of=/dev/vda"`

And restart the VPS.

After the deployment, you can use parted to extend the partition. When prompted, fix the GPT table and use `resizepart` to resize to the new end. Note that you might need to grow your btrfs filesystem using `btrfs fi resize max /nix` where `/nix` is just the path the btrfs filesystem mounted upon.

Future deployment is done by
`NIX_SSHOPTS="-i /home/ash/ash_ed25519" nixos-rebuild switch --flake .#shards --target-host ash@shards.flibrary.info --use-remote-sudo`

## 2024-06-16
- [Lanzaboote changed `bootctl` sort-key from `lanza` to `lanzaboote` and caused boot entry sorting to malfunction.](https://github.com/nix-community/lanzaboote/issues/362). Fixed by using
``
nix-collect-garbage -d
``
followed by
``
nixos-rebuild
``
to remove old boot entries (collecting garbage to remove old profile and `rebuild` to remove obsolete boot-entries).
