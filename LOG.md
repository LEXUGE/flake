# System Logs
This is a log file for incidents/changes occurred during upgrading/restructuring the configuration.

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
- [Nix has some issue with `fetchTarball` which caused `proton-ge` to not build](https://github.com/NixOS/nix/issues/10575). Fixed by ignoring this package definition temporarily.

