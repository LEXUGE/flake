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
            name = "ESP";
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
            name = "SWAP";
            type = "partition";
            start = "1G";
            end = "17G";
            part-type = "primary";
            content = {
              type = "swap";
              randomEncryption = true;
            };
          }
          {
            name = "primary";
            type = "partition";
            start = "17G";
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
            name = "primary";
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
          # use LVM striping with 2 stripes and 4 KiB each
          extraArgs = "-i 2 -I 4";
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
              "/.snapshots" = {
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
