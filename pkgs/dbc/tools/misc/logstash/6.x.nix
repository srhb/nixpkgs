{ stdenv, fetchurl, elk6Version_dbc, makeWrapper, jre  }:

stdenv.mkDerivation rec {
  version = elk6Version_dbc;
  name = "logstash-${version}";

  src = fetchurl {
    url = "https://artifacts.elastic.co/downloads/logstash/${name}.tar.gz";
    sha256 = "08c3cl90k880vlym579xj2x1zmzgixd0kq2djkphm91i8h5r1bg7";
  };

  dontBuild         = true;
  dontPatchELF      = true;
  dontStrip         = true;
  dontPatchShebangs = true;

  buildInputs = [
    makeWrapper jre
  ];

  installPhase = ''
    mkdir -p $out
    cp -r {Gemfile*,modules,vendor,lib,bin,config,data,logstash-core,logstash-core-plugin-api} $out

    patchShebangs $out/bin/logstash
    patchShebangs $out/bin/logstash-plugin

    wrapProgram $out/bin/logstash \
       --set JAVA_HOME "${jre}"

    wrapProgram $out/bin/logstash-plugin \
       --set JAVA_HOME "${jre}"
  '';

  meta = with stdenv.lib; {
    description = "Logstash is a data pipeline that helps you process logs and other event data from a variety of systems";
    homepage    = https://www.elastic.co/products/logstash;
    license     = licenses.asl20;
    platforms   = platforms.unix;
    maintainers = [ maintainers.wjlroe maintainers.offline ];
  };
}
