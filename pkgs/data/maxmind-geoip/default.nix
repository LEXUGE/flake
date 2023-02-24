{ source, lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  inherit (source) pname version src;

  phases = [ "installPhase" ];
  installPhase = ''
    install -D -m755 $src $out/Country.mmdb
  '';
}
