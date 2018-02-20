{pkgs, certs}: (
rec {

    mutableCniPath = "/var/lib/kube-router";

    cniConf = {
      name = "k8snet";
      type = "bridge";
      bridge = "kube-bridge";
      isDefaultGateway = true;
      hairpinMode = true;
      ipam = {
       type = "host-local";
      };
    };

    mkKubeConfig = name: cfg: pkgs.writeText "${name}-kubeconfig" (builtins.toJSON {
      apiVersion = "v1";
      kind = "Config";
      clusters = [{
        name = "local";
        cluster.certificate-authority = cfg.caFile;
        cluster.server = cfg.server;
      }];
      users = [{
        name = "kubelet";
        user = {
          client-certificate = cfg.certFile;
          client-key = cfg.keyFile;
        };
      }];
      contexts = [{
        context = {
          cluster = "local";
          user = "kubelet";
        };
        current-context = "kubelet-context";
      }];
    });

    routerKubeConfig = mkKubeConfig "router" {
      server = "https://api.my.domain:443";
      certFile = "${certs.master}/kubelet-client.pem";
      keyFile = "${certs.master}/kubelet-client-key.pem"; caFile = "${certs.master}/ca.pem";
    };

})
