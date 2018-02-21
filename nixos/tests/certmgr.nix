import ./make-test.nix ({ pkgs, ...} : {
  name = "cfssl";

  machine = { config, lib, pkgs, ... }:
  {
    networking.firewall.allowedTCPPorts = with config.services; [ cfssl.port certmgr.metricsPort ];

    services.cfssl.enable = true;
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

    # TODO: Actually use the certificates for a couple of vhosts and check that they work.
    services.nginx.enable = true;
    systemd.services.nginx.wantedBy = lib.mkForce [];
    systemd.services.nginx.serviceConfig.ExecStartPost = pkgs.writeScript "countstarts" ''
      #!${pkgs.bash}/bin/bash
      echo started >> /tmp/nginxstarts
    '';

    systemd.services.certmgr.after = [ "cfssl.service" ];
    services.certmgr = {
      enable = true;
      impSpecs = [
        {
          name = "test.json";
          path = "${pkgs.writeText "test.json" (builtins.toJSON {
            action = "restart";
            authority = {
              file = {
                group = "nobody";
                owner = "nobody";
                path = "/tmp/impca.pem";
              };
              label = "www_ca";
              profile = "three-month";
              remote = "localhost:8888";
            };
            certificate = {
              group = "nobody";
              owner = "nobody";
              path = "/tmp/impcert.pem";
            };
            private_key = {
              group = "nobody";
              mode = "0600";
              owner = "nobody";
              path = "/tmp/impkey.pem";
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
              })}";
            }
      ];
      declSpecs.nginx = {
        action = "restart";
        authority = {
          file = {
            group = "nobody";
            owner = "nobody";
            path = "/tmp/declca.pem";
          };
          label = "www_ca";
          profile = "three-month";
          remote = "localhost:8888";
        };
        certificate = {
          group = "nobody";
          owner = "nobody";
          path = "/tmp/declcert.pem";
        };
        private_key = {
          group = "nobody";
          mode = "0600";
          owner = "nobody";
          path = "/tmp/declkey.pem";
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
    $machine->waitUntilSucceeds('ls /tmp/declca.pem');
    $machine->waitUntilSucceeds('ls /tmp/declkey.pem');
    $machine->waitUntilSucceeds('ls /tmp/declcert.pem');
    $machine->waitUntilSucceeds('ls /tmp/impca.pem');
    $machine->waitUntilSucceeds('ls /tmp/impkey.pem');
    $machine->waitUntilSucceeds('ls /tmp/impcert.pem');
    $machine->waitForUnit('nginx.service');
    $machine->succeed('[ "2" = $(journalctl -u nginx | grep "Started Nginx" | wc -l) ]'); # FIXME: y u no work
  '';
})
