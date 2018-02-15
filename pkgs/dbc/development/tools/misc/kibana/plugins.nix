{ pkgs, fetchurl }:

with pkgs.lib;
{
 kibana_readonlyrest = rec {
    name = "kibana-readonlyrest-${version}";
    pluginName = "kibana-readonlyrest";
    version = "1.16.16_es6.2.1";
    src = fetchurl {
      url = "https://artifactory.dbc.dk/artifactory/binary-platform/kibana/readonlyrest/readonlyrest_kbn_pro-${version}.zip";
      sha256 = "0pp3n1z7ca4xr3437rdnvcwxz329f53sdfhf13fvinpxdxkhsl82";
    };

    meta = {
      homepage = https://readonlyrest.com/pro.html;
      description = "Kibana security plugin";
      license = licenses.unfree;
    };
  };


}
