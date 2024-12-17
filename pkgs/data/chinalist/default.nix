{
  source,
  lib,
  stdenv,
  fetchFromGitHub,
  format ? "raw",
  server ? "china",
}:

stdenv.mkDerivation rec {
  inherit (source) pname version src;

  makeFlags = [
    format
    "SERVER=${server}"
  ];

  installPhase = ''
    mkdir $out
    cp ./*${format}* $out
  '';

  meta = with lib; {
    description = "Chinese-specific configuration to improve your favorite DNS server.";
    longDescription = ''
      Chinese-specific configuration to improve your favorite DNS server. Best partner for chnroutes.
    '';
    homepage = "https://github.com/felixonmars/dnsmasq-china-list";
    license = licenses.free;
    platforms = platforms.all;
  };
}
