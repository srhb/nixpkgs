{ pkgs, stdenv, fetchurl, unzip, elasticsearch, zip }:

with pkgs.lib;

{
  elasticsearch_readonlyrest = stdenv.mkDerivation rec {
    name = "elasticsearch-readonlyrest-${version}";
    pluginName = "elasticsearch-readonlyrest";
    version = "1.16.16_es6.2.1";
    src = fetchurl {
      url = "https://artifactory.dbc.dk/artifactory/binary-platform/elasticsearch/readonlyrest/readonlyrest-${version}.zip";
      sha256 = "11w8b7mlg9sd8kj27ql803glw65pgv68dbk5mf3z4n4mblv24zbw";
    };

    buildInputs = [ zip unzip ];
    patches = [ ./ror-policy.patch ];

    installPhase = ''
      zip -r out.zip .
      mkdir -p $out/bin
      ES_HOME=$out ${elasticsearch}/bin/elasticsearch-plugin --install ${pluginName} --url file://$(readlink -e out.zip)
    '';

    meta = {
      homepage = https://github.com/sscarduzio/elasticsearch-readonlyrest-plugin;
      description = "Elasticsearch and Kibana security plugin";
      license = licenses.gpl3;
    };
  };
}
