{ lib, stdenv, fetchFromGitHub, format ? "raw", server ? "china" }:

stdenv.mkDerivation rec {
  pname = "chinalist-${format}";
  version = "2022-09-22";

  src = fetchFromGitHub {
    owner = "felixonmars";
    repo = "dnsmasq-china-list";
    rev = "390a296a8094b0a8f9368766867df7b61424efd4";
    sha256 = "sha256-TEl5jQ7/Qpw5fHXHBG513nQOEOPMo/bhdZ1mXL/3IHM=";
  };

  makeFlags = [ format "SERVER=${server}" ];

  installPhase = ''
    mkdir $out
    cp ./*${format}* $out
  '';

  meta = with lib; {
    description =
      "Chinese-specific configuration to improve your favorite DNS server.";
    longDescription = ''
      Chinese-specific configuration to improve your favorite DNS server. Best partner for chnroutes.
    '';
    homepage = "https://github.com/felixonmars/dnsmasq-china-list";
    license = licenses.free;
    platforms = platforms.all;
  };
}
