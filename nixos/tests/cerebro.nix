# Test cerebro standalone web app  

import ./make-test.nix ({ pkgs, ...} :
let
  cerebroUrl = "http://localhost:9000";
  testPort = 9001;
in { 
  name = "Cerebro";


  nodes = {
    one =
    { config, pkgs, ... }: {
      services = {
        cerebro = {
          enable = true;
          package = pkgs.cerebro;
          port = testPort;
        };
      };
    };
  };

  testScript = ''
    startAll;
    # See if Cerebro is running locally.
    $one->waitForUnit("cerebro.service");
    $one->waitUntilSucceeds("curl --silent --show-error 'http://localhost:${toString testPort}'");
  '';
})
