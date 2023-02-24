{ lib, pkgs, overlay ? false }:
let
  # All source files generated by nvfetcher
  sources = (import ./_sources/generated.nix) { inherit (pkgs) fetchurl fetchgit fetchFromGitHub dockerTools; };
  listPackageRecursive = with builtins;
    dir:
    (lib.lists.foldr (n: col: col // n) { } (lib.attrsets.mapAttrsToList
      (name: type:
        let path = dir + "/${name}";
        in if type == "directory" then
          if builtins.pathExists (path + "/default.nix") then
            if overlay then
              { "${name}" = (pkgs.callPackage path { source = sources.${name}; }); }
            else
              { "${name}" = pkgs."${name}"; }
          else
            listPackageRecursive path
        else
          { })
      (builtins.readDir dir)));
in
listPackageRecursive ./.
