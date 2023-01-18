{ disks ? [ "/dev/nvme0n1" "/dev/mmcblk0" ], ... }: {
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
            end = "9G";
            content = {
              type = "luks";
              name = "cryptswap";
              content = {
                type = "swap";
              };
            };
          }
          {
            name = "raw-pool-root-1";
            type = "partition";
            start = "9G";
            end = "100%";
            content = {
              type = "lvm_pv";
              vg = "pool";
            };
          }
        ];
      };
    };
    microsd = {
      type = "disk";
      device = builtins.elemAt disks 1;
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            name = "raw-pool-root-2";
            type = "partition";
            start = "0";
            end = "100%";
            content = {
              type = "lvm_pv";
              vg = "pool";
            };
          }
        ];
      };
    };
  };

  lvm_vg = {
    pool = {
      type = "lvm_vg";
      lvs = {
        root = {
          type = "lvm_lv";
          size = "100%FREE";
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
        };
      };
    };
  };
}
