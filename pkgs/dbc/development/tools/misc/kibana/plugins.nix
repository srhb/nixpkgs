{ pkgs, fetchurl }:

with pkgs.lib;
{
 kibana_readonlyrest = rec {
    name = "kibana-readonlyrest-${version}";
    pluginName = "kibana-readonlyrest";
    version = "1.16.15_es6.1.1";
    src = fetchurl {
      url = "https://artifactory.dbc.dk/artifactory/binary-platform/kibana/readonlyrest/readonlyrest_kbn_pro-${version}.zip";
      sha256 = "0xn3k63fxar881mn4nmmi1vjs71vsj33znmnfjn8mhrc6sw6kf1f";
    };

    meta = {
      homepage = https://readonlyrest.com/pro.html;
      description = "Kibana security plugin";
      license = licenses.unfree;
    };
  };


}
