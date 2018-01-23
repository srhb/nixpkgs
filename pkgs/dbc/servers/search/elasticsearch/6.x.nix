{ stdenv, fetchurl, elk6Version_dbc, makeWrapper, jre_headless, utillinux, getopt }:

with stdenv.lib;

stdenv.mkDerivation rec {
  version = elk6Version_dbc;
  name = "elasticsearch-${version}";

  src = fetchurl {
    url = "https://artifacts.elastic.co/downloads/elasticsearch/${name}.tar.gz";
    sha256 = "1x6rwf8y64cafs9i1ypxhrqy9r796w3pf0zn8i94i1mrm1vyh804";
  };

  buildInputs = [ makeWrapper jre_headless ] ++
    (if (!stdenv.isDarwin) then [utillinux] else [getopt]);

  installPhase = ''
    mkdir -p $out
    cp -R bin config lib modules plugins $out

    chmod -x $out/bin/*.*
    cat > $out/bin/elasticsearch-env <<-EOF
      if [ -z "\$ES_HOME" ]; then
          echo "You must set the ES_HOME var" >&2
          exit 1
      fi
      if [ -z "\$ES_PATH_CONF" ]; then
          echo "You must set the ES_PATH_CONF var" >&2
          exit 1
      fi
      JAVA="${jre_headless}"/bin/java
    EOF

    wrapProgram $out/bin/elasticsearch \
      --prefix ES_CLASSPATH : "$out/lib/*" \
      ${if (!stdenv.isDarwin)
        then ''--prefix PATH : "${utillinux}/bin/"''
        else ''--prefix PATH : "${getopt}/bin"''} \
      --set JAVA_HOME "${jre_headless}" \
      --set ES_JVM_OPTIONS "$out/config/jvm.options"

    wrapProgram $out/bin/elasticsearch-plugin --set JAVA_HOME "${jre_headless}"
  '';

  meta = {
    description = "Open Source, Distributed, RESTful Search Engine";
    license = licenses.asl20;
    platforms = platforms.unix;
    maintainers = [
      maintainers.apeschar
    ];
  };
}
