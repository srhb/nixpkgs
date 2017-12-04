{ stdenv, fetchurl, jre_headless, makeWrapper }:

stdenv.mkDerivation rec {
  name = "cerebro-${version}";
  version = "0.7.2";

  src = fetchurl {
    url = "https://github.com/lmenezes/cerebro/releases/download/v${version}/cerebro-${version}.tgz";
    sha256 = "0jlvzbng21ps09v5vwx9mh6jfb5mwkwirm8mrvam09c356yikw63";
  };

  buildInputs = [ makeWrapper jre_headless ];

  installPhase = ''
    mkdir $out
    cp -r bin conf lib README.md $out/
    wrapProgram $out/bin/cerebro --set JAVA_HOME "${jre_headless}"

    substituteInPlace $out/conf/application.conf --replace 'data.path = "./cerebro.db"' 'data.path = "/tmp/cerebro.db"'
    substituteInPlace $out/conf/logback.xml --replace '<file>''${application.home:-.}/logs/application.log</file>' '<file>/tmp/logs/cerebro.log</file>'

  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/lmenezes/cerebro/;
    description = "cerebro is an open source(MIT License) elasticsearch web admin tool built using Scala, Play Framework, AngularJS and Bootstrap.";
    license = licenses.mit;
    platforms = platforms.all;
  };

}
