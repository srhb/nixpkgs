{ pkgs, fetchurl }:

with pkgs.lib;
{
 kibana_readonlyrest = rec {
    name = "kibana-readonlyrest-${version}";
    pluginName = "kibana-readonlyrest";
    version = "1.16.15";
    src = fetchurl {
      url = "https://artifactory.dbc.dk/artifactory/binary-platform/kibana/readonlyrest/readonlyrest_kbn_pro-${version}_es6.0.0.zip";
      sha256 = "17a40cc90db9ce471488021c30b29b8a5baccef4d8e35d927127e2b6901ad302";
      name = "readonlyrest_kbn_pro-${version}_es6.0.0.zip";
    };

    meta = {
      homepage = https://readonlyrest.com/pro.html;
      description = "Kibana security plugin";
      license = licenses.unfree;
    };
  };


}
