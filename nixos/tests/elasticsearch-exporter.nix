# Test   

import ./make-test.nix ({ pkgs, ...} :
let
  # cerebroUrl = "http://localhost:9000";
  # testPort = 9001;
in { 
  name = "elasticsearch-export";


  nodes = {
    one =
    { config, pkgs, ... }: {
      services = {
         prometheus.elasticsearchExporter = {
         enable = true;
        };
      };
    };
  };

  testScript = ''
    startAll;
    # See if elasticsearch-exporter is running locally.
    $one->waitForUnit("prometheus-elasticsearch-exporter.service");
  '';
})
