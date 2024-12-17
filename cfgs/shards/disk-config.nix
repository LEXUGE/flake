{
  disko.devices.disk = {
    sda = {
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          # ESP
          esp = {
            size = "500M";
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
            size = "4G";
            content = {
              type = "swap";
            };
          };
          # Root partition
          root = {
            size = "100%";
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
              };
            };
          };
        };
      };
    };
  };
}
