{ lib, fetchzip, stdenv }:

stdenv.mkDerivation rec {
  pname = "yacd";
  version = "0.3.6";

  src = fetchzip {
    url =
      "https://github.com/haishanh/yacd/releases/download/v${version}/yacd.tar.xz";
    sha256 = "sha256-vjt67cE9HUc+G2XyPR+IZPgVvjizatQVqIyxeUUAJow=";
  };

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
