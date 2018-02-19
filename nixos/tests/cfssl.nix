import ./make-test.nix ({ pkgs, ...} : {
  name = "cfssl";

  machine = { config, lib, pkgs, ... }:
  {
    networking.firewall.allowedTCPPorts = [ 8080 8888 ];
    services.cfssl.enable = true;
    services.nginx.enable = true;
    services.certmgr = {
      enable = true;
      specs.nginx = {
        action = "restart";
        authority = {
          #auth_key = "012345678012345678";
          file = {
          group = "nobody";
          owner = "nobody";
          path = "/tmp/ca.pem";
          };
          label = "www_ca";
          profile = "three-month";
          remote = "localhost:8888";
        };
        certificate = {
          group = "nobody";
          owner = "nobody";
          path = "/tmp/test1.pem";
        };
        private_key = {
          group = "nobody";
          mode = "0600";
          owner = "nobody";
          path = "/tmp/www.key";
        };
        request = {
          CN = "www.example.net";
          hosts = [ "example.net" "www.example.net" ];
          key = {
            algo = "ecdsa";
            size = 521;
          };
          names = [
            {
              C = "US";
              L = "San Francisco";
              O = "Example, LLC";
              ST = "CA";
            }
          ];
        };
        service = "nginx";
      };
    };
  };

  testScript = ''
    $machine->waitForUnit('cfssl');
  '';
})
