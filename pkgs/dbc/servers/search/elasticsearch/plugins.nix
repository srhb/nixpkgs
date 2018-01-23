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
    version = "1.16.15";
    src = fetchurl {
      url = "https://artifactory.dbc.dk/artifactory/binary-platform/elasticsearch/readonlyrest/readonlyrest-${version}_es6.0.0.zip";
      sha256 = "eb61410ae98f6f68121fd1e815eb04b940ca023248d91102896ca276aea7d48b";
      name = "readonlyrest-${version}_es6.0.0.zip";
    };

    meta = {
      homepage = https://github.com/sscarduzio/elasticsearch-readonlyrest-plugin;
      description = "Elasticsearch and Kibana security plugin";
      license = licenses.gpl3;
    };
  };
}
