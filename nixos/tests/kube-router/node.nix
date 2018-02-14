{pkgs, hostName, ip, domain, certs, hosts, sshPort}: (

let
  fqdn = "${hostName}.${domain}";

  router = import ./router.nix { inherit pkgs; inherit certs; };

  podCidr = "10.100.0.0/16";

  services = {

    openssh = {
      enable = true;
      permitRootLogin = "yes";
    };

    kube-router = {
      enable = true;
      hostName = fqdn;
      kubeConfig = router.routerKubeConfig;
      cniConfig = router.cniConf;
      mutableCniPath = router.mutableCniPath;
      enableServiceProxy = false;
      enablePodSNAT = false;
      enableHairpinMode = true;
    };

    kubernetes = {
      caFile = "${certs.worker}/ca.pem";
      roles = [ "node" ];

      clusterCidr = podCidr;
      featureGates = ["SupportIPVSProxyMode"];

      kubelet = with pkgs; {
        tlsCertFile = "${certs.worker}/kubelet.pem";
        tlsKeyFile = "${certs.worker}/kubelet-key.pem";
        hostname = fqdn;
        kubeconfig = {
          server = "https://api.my.domain:443";
          certFile = "${certs.worker}/apiserver-client-kubelet-${hostName}.pem";
          keyFile = "${certs.worker}/apiserver-client-kubelet-${hostName}-key.pem";
        };

        networkPlugin = "cni";
        cni.packages = [ cni ];
        cni.configDir = router.mutableCniPath;
      };

      proxy = {
        enable = true;
        extraOpts = "--proxy-mode=ipvs";
        kubeconfig = {
          server = "https://api.my.domain:443";
          certFile = "${certs.worker}/apiserver-client-kube-proxy.pem";
          keyFile = "${certs.worker}//apiserver-client-kube-proxy-key.pem";
        };
      };
    };
  };

in
  import ./base.nix { inherit pkgs; inherit hostName; inherit ip; inherit domain; inherit services; inherit sshPort; inherit hosts; inherit certs; })
