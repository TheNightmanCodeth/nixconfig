{ lib, requireFile, stdenvNoCC, unzip }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "berkeley-mono";
  version = "1.000";

  src = requireFile rec {
    name = "berkeley-mono-combined.zip";
    sha256 = "1sdbfwibv9wsm9k9l220srilcmay5jm5ljpz33i3j9hjrcc8wjnr";
    message = "poopy";
  };

  outputs = [ "out" ];

  nativeBuildInputs = [
    unzip
  ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    runHook preInstall

    install -D -m444 -t $out/share/fonts/opentype berkeley-mono-combined/OTF/*.otf
    install -D -m444 -t $out/share/fonts/truetype berkeley-mono-combined/TTF/*.ttf

    runHook postInstall
  '';


})
