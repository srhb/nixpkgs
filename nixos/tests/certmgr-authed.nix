import ./make-test.nix ({ pkgs, ...} : {
  name = "cfssl";

  machine = { config, lib, pkgs, ... }:
  {
    networking.firewall.allowedTCPPorts = with config.services; [ cfssl.port certmgr.metricsPort ];

    services.cfssl = {
      enable = true;
    };
    systemd.services.cfssl.after = [ "cfssl-init.service" "networking.target" ];

    systemd.services.cfssl-init = {
      description = "Initialize the cfssl CA";
      wantedBy    = [ "multi-user.target" ];
      serviceConfig = {
        User             = "cfssl";
        Type             = "oneshot";
        WorkingDirectory = config.services.cfssl.dataDir;
      };
      script = with pkgs; ''
        ${cfssl}/bin/cfssl genkey -initca ${pkgs.writeText "ca.json" (builtins.toJSON {
          hosts = [ "ca.example.com" ];
          key = {
            algo = "rsa"; size = 4096; };
            names = [
              {
                C = "US";
                L = "San Francisco";
                O = "Internet Widgets, LLC";
                OU = "Certificate Authority";
                ST = "California";
              }
            ];
        })} | ${cfssl}/bin/cfssljson -bare ca
      '';
    };


    services.nginx.enable = true;
    systemd.services.certmgr.after = [ "cfssl.service" ];
    services.certmgr = {
      enable = true;
      specs.nginx = {
        action = "restart";
        authority = {
          file = {
          group = "nobody";
          owner = "nobody";
          path = "/tmp/ca.pem";
          };
          label = "www_ca";
          profile = "three-month";
          remote = "localhost:8888";
          auth_key = "012345678012345678";
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
    $machine->waitForUnit('cfssl.service');
    $machine->waitUntilSucceeds('ls /tmp/www.key');
    $machine->waitUntilSucceeds('ls /tmp/test1.pem');
  '';
})
