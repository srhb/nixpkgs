import ./make-test.nix ({ pkgs, ...} :

with import ./kubernetes/base.nix { };
let
  domain = "my.domain";

  hostName = "machine";
  primaryIp = "127.0.0.1";

  serviceCidr = "10.90.0.0/16";
  podCidr = "10.100.0.0/16";

  certs = import ./kubernetes/certs.nix { externalDomain = domain; serviceClusterIp = "10.90.0.1"; };

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

  routerKubeConfig = mkKubeConfig "router" {
    server = "https://api.my.domain:443";
    certFile = "${certs.master}/kubelet-client.pem";
    keyFile = "${certs.master}/kubelet-client-key.pem"; caFile = "${certs.master}/ca.pem";
  };

  mc = {
    networking = {
      firewall.allowedTCPPortRanges = [
           { from = 2379; to = 2380; } # etcd
           { from = 443; to = 443; } # kubernetes.apiserver
      ];

      extraHosts = pkgs.lib.concatStringsSep "\n" ["127.0.0.1 ${hostName}.${domain}" "192.168.1.1 api.${domain}"];
    };

   virtualisation.docker.enable = true;
   virtualisation.memorySize = 1024;

   virtualisation.qemu.options = [ "-redir tcp:2221::22" "-redir tcp:8001::8001" ];

   boot.initrd.postDeviceCommands = ''
       ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L var /dev/vdb
   '';

   virtualisation.emptyDiskImages = [ 4096 ];

   fileSystems = pkgs.lib.mkVMOverride {
     "/var" = {
       device = "/dev/vdb";
       fsType = "ext4";
       options = [ "noauto" ];
     };
   };


    services = {

      kube-router = {
        enable = true;
        hostName = "${hostName}.${domain}";
        kubeConfig = routerKubeConfig;
        cniConfig = cniConf;
        mutableCniPath = "/var/lib/kube-router";
        enableServiceProxy = false;
        enablePodSNAT = false;
        peerRouters = [ { ip = "192.168.0.1"; asn = 13244; password = "keepmesecret"; } ];
      };

      etcd = {
        enable = true;

        advertiseClientUrls      = [ "http://127.0.0.1:2379" ];
        initialAdvertisePeerUrls = [ "http://127.0.0.1:2380" ];
        initialCluster           = [ "machine=http://127.0.0.1:2380" ];
        initialClusterState      = "new";
        initialClusterToken      = "k8s-p1";
        listenClientUrls         = [ "http://127.0.0.1:2379" ];
        listenPeerUrls           = [ "http://127.0.0.1:2380" ];
        name                     = hostName;
      };

       openssh = {
         enable = true;
         permitRootLogin = "yes";
       };

       kubernetes = {
         etcd.servers = ["http://127.0.0.1:2379"];
         caFile = "${certs.master}/ca.pem";

         addons.dashboard.enable = true;

         roles = [ "master" "node" ];
         flannel.enable = false;
         clusterCidr = podCidr;

         kubelet = with pkgs; {
           tlsCertFile = "${certs.worker}/kubelet.pem";
           tlsKeyFile = "${certs.worker}/kubelet-key.pem";
           hostname = "${hostName}.${domain}";
           kubeconfig = {
             certFile = "${certs.worker}/apiserver-client-kubelet.pem";
             keyFile = "${certs.worker}/apiserver-client-kubelet-key.pem";
           };

           networkPlugin = "cni";
           cni.packages = [ cni ];
           cni.configDir = mc.services.kube-router.mutableCniPath;
         };

         controllerManager = {
           enable = true;
           serviceAccountKeyFile = "${certs.master}/kube-service-accounts-key.pem";
           kubeconfig = {
             certFile = "${certs.master}/apiserver-client-kube-controller-manager.pem";
             keyFile = "${certs.master}/apiserver-client-kube-controller-manager-key.pem";
           };
         };

         scheduler = {
           enable = true;
           kubeconfig = {
             certFile = "${certs.master}/apiserver-client-kube-scheduler.pem";
             keyFile = "${certs.master}/apiserver-client-kube-scheduler-key.pem";
           };
         };

         proxy = {
           enable = true;
           kubeconfig = {
             certFile = "${certs.worker}/apiserver-client-kube-proxy.pem";
             keyFile = "${certs.worker}//apiserver-client-kube-proxy-key.pem";
           };
         };

         apiserver = {
           enable = true;
           address = primaryIp ;
           publicAddress = "api.${domain}";
           tlsCertFile = "${certs.master}/kube-apiserver.pem";
           tlsKeyFile = "${certs.master}/kube-apiserver-key.pem";
           kubeletClientCertFile = "${certs.master}/kubelet-client.pem";
           kubeletClientKeyFile = "${certs.master}/kubelet-client-key.pem";
           serviceAccountKeyFile = "${certs.master}/kube-service-accounts.pem";
           serviceClusterIpRange = serviceCidr;
           authorizationMode = ["AlwaysAllow"];
           basicAuthFile = null;
         };

       };

    };
 };

 nginxManifest = pkgs.writeText "nginx-manifest.json" (builtins.toJSON {
                   apiVersion = "extensions/v1beta1";
                   kind = "Deployment";
                   metadata = {
                     name = "nginx-deployment";
                   };
                   spec = {
                     selector = {
                       matchLabels = {
                         app = "nginx";
                       };
                     };
                     replicas = 2;
                     template = {
                       metadata = {
                         labels = {
                           app = "nginx";
                         };
                       };
                       spec = {
                         containers = [{
                           name = "nginx";
                           image = "nginx:1.7.9";
                           ports = [{ containerPort = 80; }];
                         }];
                       };
                     };
                   };
                 });
in
{
  name = hostName;

  machine = mc;

  # TODO: Test of Pod-To-Pod networking
  # TODO: Test of external peering
  # TODO: Test of service networking

  testScript = ''
    $machine->waitUntilSucceeds("kubectl get node ${hostName}.${domain} | grep -w Ready");
    $machine->succeed("kubectl apply -f ${nginxManifest}");
    $machine->waitUntilSucceeds("test \$(kubectl get pods | grep -c Running) == 2");
  '';
})
