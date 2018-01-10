{ pkgs, stdenv, fetchurl, fetchFromGitHub, unzip, kibana }:

with pkgs.lib;

let
  kibanaPlugin = a@{
    pluginName,
    installPhase ? ''
      mkdir -p $out/bin
      KIBANA_HOME=$out ${kibana}/bin/kibana-plugin --install ${pluginName} --url file://$src
    '',
    ...
  }:
    stdenv.mkDerivation (a // {
      inherit installPhase;
      unpackPhase = "true";
      buildInputs = [ unzip ];
      meta = a.meta // {
        platforms = kibana.meta.platforms;
        maintainers = (a.meta.maintainers or []) ++ [ maintainers.offline ];
      };
    });
in {

 kibana_readonlyrest = kibanaPlugin rec {
    name = "kibana-readonlyrest-${version}";
    pluginName = "kibana-readonlyrest";
    version = "1.16.14";
    src = fetchurl {
      url = "https://artifactory.dbc.dk/artifactory/binary-platform/kibana/readonlyrest/readonlyrest_kbn_pro-1.16.14-20171211_es6.0.0.zip";
      sha256 = "15kpmdvmiy2pj7laqxxprzb6rxmi0ckcdmsxjnnbcqvji40gmdcn";
      name = "readonlyrest_kbn_pro-${version}-20180108_es6.0.0.zip";
    };

    meta = {
      homepage = https://readonlyrest.com/pro.html;
      description = "Kibana security plugin";
      license = licenses.unfree;
    };
  };


}
