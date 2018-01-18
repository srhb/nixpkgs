{ mkDerivation, aeson, base, containers, data-fix, hnix, lens
, lens-aeson, fetchurl, mtl, optparse-applicative, stdenv, text, turtle
}:
mkDerivation rec {
  pname = "nixdeploy";
  version = "pre25_1453af2";
  src = fetchurl {
    url = "https://hydra-platform.dbc.dk/build/157057/download/1/nixdeploy-${version}.tar.bz2";
    sha256 = "0fkvchsz252sp0k296qznzy8pn6fwzzl06h8q4lb1k8dcrgdr8si";
  };
  isLibrary = false;
  isExecutable = true;
  enableSeparateDataOutput = true;
  executableHaskellDepends = [
    aeson base containers data-fix hnix lens lens-aeson mtl
    optparse-applicative text turtle
  ];
  license = stdenv.lib.licenses.gpl3;
  postInstall = ''
    mkdir -p $out/etc/bash_completion.d
    $out/bin/nixdeploy --bash-completion-script $out/bin/nixdeploy > $out/etc/bash_completion.d/nixdeploy-completion.bash
  '';
}
