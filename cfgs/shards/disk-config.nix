{
  disko.devices.disk = {
    main = {
      imageSize = "3G";
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            priority = 0;
            size = "1M";
            type = "EF02";
          };
          # ESP
          esp = {
            # label = "esp";
            size = "500M";
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
            # label = "swap";
            size = "1G";
            priority = 2;
            content = {
              type = "swap";
            };
          };
          # Root partition
          root = {
            # label = "root";
            priority = 3;
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
