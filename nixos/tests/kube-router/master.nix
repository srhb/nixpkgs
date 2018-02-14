{pkgs, hostName, ip, domain, certs, hosts, sshPort}: (

let
      serviceCidr = "10.90.0.0/16";
      podCidr = "10.100.0.0/16";
      fqdn = "${hostName}.${domain}";

      router = import ./router.nix { inherit pkgs; inherit certs; };

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

        etcd = {
          enable = true;

          advertiseClientUrls      = [ "http://127.0.0.1:2379" ];
          initialAdvertisePeerUrls = [ "http://127.0.0.1:2380" ];
          initialCluster           = [ "${hostName}=http://127.0.0.1:2380" ];
          initialClusterState      = "new";
          initialClusterToken      = "k8s-p1";
          listenClientUrls         = [ "http://127.0.0.1:2379" ];
          listenPeerUrls           = [ "http://127.0.0.1:2380" ];
          name                     = hostName;
        };

         kubernetes = {
           etcd.servers = ["http://127.0.0.1:2379"];
           caFile = "${certs.master}/ca.pem";

           roles = [ "master" ];
           flannel.enable = false;
           clusterCidr = podCidr;

           featureGates = ["SupportIPVSProxyMode"];

           kubeconfig = { server = "https://api.my.domain:443"; };


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
             extraOpts = "--proxy-mode=ipvs";
             kubeconfig = {
               certFile = "${certs.worker}/apiserver-client-kube-proxy.pem";
               keyFile = "${certs.worker}//apiserver-client-kube-proxy-key.pem";
             };
           };

           kubelet = with pkgs; {
             tlsCertFile = "${certs.worker}/kubelet.pem";
             tlsKeyFile = "${certs.worker}/kubelet-key.pem";
             hostname = fqdn;
             kubeconfig = {
               certFile = "${certs.worker}/apiserver-client-kubelet-${hostName}.pem";
               keyFile = "${certs.worker}/apiserver-client-kubelet-${hostName}-key.pem";
             };

             networkPlugin = "cni";
             cni.packages = [ cni ];
             cni.configDir = router.mutableCniPath;
           };

           apiserver = {
             enable = true;
             #address = "192.168.1.1";
             publicAddress = "192.168.1.1";
             #advertiseAddress = "api.${domain}";
             advertiseAddress = "192.168.1.1";
             tlsCertFile = "${certs.master}/kube-apiserver.pem";
             tlsKeyFile = "${certs.master}/kube-apiserver-key.pem";
             kubeletClientCertFile = "${certs.master}/kubelet-client.pem";
             kubeletClientKeyFile = "${certs.master}/kubelet-client-key.pem";
             serviceAccountKeyFile = "${certs.master}/kube-service-accounts-key.pem";
             serviceClusterIpRange = serviceCidr;
             authorizationMode = ["AlwaysAllow"];
             basicAuthFile = null;
           };

         };

      };

in
  import ./base.nix { inherit pkgs; inherit hostName; inherit ip; inherit domain; inherit services; inherit certs; inherit hosts; inherit sshPort; })
