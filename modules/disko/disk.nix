{ device ? "/dev/nvme0n1", ... }: {
  disk = {
    nvme = {
      type = "disk";
      inherit device;
      content = {
        type = "gpt";
        partitions = {
          # ESP
          esp = {
            start = "0";
            end = "1G";
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
            start = "1G";
            end = "21G";
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
            start = "21G";
            end = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              content = {
                type = "btrfs";
                subvolumes = {
                  # Mountpoints now must be explicitly stated
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist/home" = {
                    mountpoint = "/persist/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/tmp" = {
                    mountpoint = "/tmp";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/.snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [ "compress=zstd" "noatime" ];
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
