{
  device ? "/dev/nvme0n1",
  swap,
  ...
}:
with builtins;
{
  disk = {
    nvme = {
      type = "disk";
      inherit device;
      content = {
        type = "gpt";
        partitions = {
          # ESP
          esp = {
            label = "esp";
            size = "1G";
            priority = 1;
            # EFI Filesystem
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          # Swap
          swap = {
            label = "swap";
            size = "${toString swap}G";
            priority = 2;
            content = {
              type = "luks";
              name = "cryptswap";
              content = {
                type = "swap";
              };
            };
          };
          # Root partition
          root = {
            label = "root";
            size = "100%";
            priority = 3;
            content = {
              type = "luks";
              name = "cryptroot";
              content = {
                type = "btrfs";
                subvolumes = {
                  # Mountpoints now must be explicitly stated
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/persist/home" = {
                    mountpoint = "/persist/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/tmp" = {
                    mountpoint = "/tmp";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/.snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
