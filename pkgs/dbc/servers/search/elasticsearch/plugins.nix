{ pkgs, stdenv, fetchurl, unzip, elasticsearch }:

with pkgs.lib;

let
  esPlugin = a@{
    pluginName,
    installPhase ? ''
      mkdir -p $out/bin
      ES_HOME=$out ${elasticsearch}/bin/elasticsearch-plugin --install ${pluginName} --url file://$src
    '',
    ...
  }:
    stdenv.mkDerivation (a // {
      inherit installPhase;
      unpackPhase = "true";
      buildInputs = [ unzip ];
      meta = a.meta // {
        platforms = elasticsearch.meta.platforms;
        maintainers = (a.meta.maintainers or []) ++ [ maintainers.offline ];
      };
    });
in {
  elasticsearch_readonlyrest = esPlugin rec {
    name = "elasticsearch-readonlyrest-${version}";
    pluginName = "elasticsearch-readonlyrest";
    version = "1.16.15_es6.1.1";
    src = fetchurl {
      url = "https://artifactory.dbc.dk/artifactory/binary-platform/elasticsearch/readonlyrest/readonlyrest-${version}.zip";
      sha256 = "1zbmmlps5b95dbdb7ppph58q5ij8160dwg6baxhrlch1dzvg2sbi";
    };

    meta = {
      homepage = https://github.com/sscarduzio/elasticsearch-readonlyrest-plugin;
      description = "Elasticsearch and Kibana security plugin";
      license = licenses.gpl3;
    };
  };
}
