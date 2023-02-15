{ disks ? [ "/dev/nvme0n1" ], ... }: {
  disk = {
    nvme = {
      type = "disk";
      device = builtins.elemAt disks 0;
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          # ESP
          {
            name = "esp";
            type = "partition";
            start = "0";
            end = "1G";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }
          # Swap
          {
            name = "swap";
            type = "partition";
            start = "1G";
            end = "21G";
            content = {
              type = "luks";
              name = "cryptswap";
              content = {
                type = "swap";
              };
            };
          }
          # Root partition
          {
            name = "root";
            type = "partition";
            start = "21G";
            end = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              content = {
                type = "btrfs";
                subvolumes = {
                  # Mountpoints inferred from subvolume name
                  "/persist" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist/home" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/tmp" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/.snapshots" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          }
        ];
      };
    };
  };
}
