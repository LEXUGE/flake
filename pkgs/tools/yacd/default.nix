{ source, lib, fetchzip, stdenv }:

stdenv.mkDerivation rec {
  inherit (source) pname version src;

  installPhase = ''
    mkdir -p $out/bin
    cp -r . $out/bin
  '';

  meta = with lib; {
    description = "Yet Another Clash Dashboard";
    homepage = "https://github.com/haishanh/yacd";
    license = licenses.free;
    platforms = platforms.all;
  };
}
