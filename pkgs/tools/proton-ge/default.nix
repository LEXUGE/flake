{ lib, stdenv, source }:
stdenv.mkDerivation rec {
  inherit (source) pname src version;

  nativeBuildInputs = [ ];

  installPhase = ''
    mkdir -p $out
    mv * $out/
  '';
}
