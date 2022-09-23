{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "maxmind-geoip";
  version = "20220912";

  src = fetchurl {
    url =
      "https://github.com/Dreamacro/${pname}/releases/download/${version}/Country.mmdb";
    sha256 = "sha256-YIQjuWbizheEE9kgL+hBS1GAGf2PbpaW5mu/lim9Q9A=";
  };

  phases = [ "installPhase" ];
  installPhase = ''
    install -D -m755 $src $out/Country.mmdb
  '';
}
