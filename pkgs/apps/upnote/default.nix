{ source, lib, appimageTools }:

let
  appimageContents = appimageTools.extractType2 {
    inherit (source) pname version src;
  };
in
appimageTools.wrapType2 rec {
  inherit (source) pname version src;
  extraInstallCommands = ''
    mv $out/bin/${pname}-${version} $out/bin/${pname}

    install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
    install -m 444 -D ${appimageContents}/${pname}.png $out/share/icons/hicolor/512x512/apps/${pname}.png
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
  '';
}
