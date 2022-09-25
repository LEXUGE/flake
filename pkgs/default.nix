{ lib, pkgs }:
let
  listPackageRecursive = with builtins;
    dir:
    (lib.lists.foldr (n: col: col // n) { } (lib.attrsets.mapAttrsToList
      (name: type:
        let path = dir + "/${name}";
        in if type == "directory" then
          if builtins.pathExists (path + "/default.nix") then
            { "${name}" = (pkgs.callPackage path { }); }
          else
            listPackageRecursive path
        else
          { })
      (builtins.readDir dir)));
in
listPackageRecursive ./.
