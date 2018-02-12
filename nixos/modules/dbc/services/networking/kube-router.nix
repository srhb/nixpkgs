{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.kube-router;

  # CNI-config file name is hardcoded in kube-router source code
  cniConfigFileName = "10-kuberouter.conf";
  cniFile = pkgs.writeText "cni.cfg" (builtins.toJSON cfg.cniConfig);

  preStart = mkIf (cfg.cniConfig != null)
          ''
            if [[ ! -f ${cfg.mutableCniPath}/${cniConfigFileName} ]]; then
              mkdir -p ${cfg.mutableCniPath}
              cp ${cniFile} ${cfg.mutableCniPath}/${cniConfigFileName}
            fi
          '';

  start = ''
           ${pkgs.kube-router}/bin/kube-router \
           ${optionalString (cfg.kubeConfig != null) "--kubeconfig " + cfg.kubeConfig} \
           --hostname-override=${cfg.hostName} \
           --run-router=${boolToString cfg.enableRouter} \
           --run-firewall=${boolToString cfg.enableFirewall} \
           --run-service-proxy=${boolToString cfg.enableServiceProxy} \
           --advertise-cluster-ip=${boolToString cfg.advertiseServiceClusterIP} \
           --advertise-external-ip=${boolToString cfg.advertiseServiceExternalIP} \
           --enable-overlay=${boolToString cfg.enablePodOverlayNetwork} \
           --hairpin-mode=${boolToString cfg.enableHairpinMode} \
           --enable-pod-egress=${boolToString cfg.enablePodSNAT}
           --peer-router-asns=${concatMapStringsSep "," (router: toString router.asn) cfg.peerRouters} \
           --peer-router-ips=${concatMapStringsSep "," (router: router.ip) cfg.peerRouters} \
           --peer-router-passwords=${concatMapStringsSep "," (router: router.password) cfg.peerRouters} \
         '';
in
{
  options = {

    services.kube-router = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the kube-router module.";
      };

      hostName = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = "Override hostname used by kube-router.";
      };

      kubeConfig = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/path/to/kubeconfig.json";
        description = "Path to kubeconfig file";
      };

      enableRouter = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable the kube-router router component.";
      };

      enableFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable the kube-router firewall component.";
      };

      enableServiceProxy = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable the kube-router service-proxy component.";
      };

      advertiseServiceClusterIP = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to advertise service clusterIP's to BGP peers.";
      };

      advertiseServiceExternalIP = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to advertise service externalIP's to BGP peers.";
      };

      enablePodOverlayNetwork = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable IPIP tunneling overlay network for pod-to-pod traffic.";
      };

      enableHairpinMode = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable clusterwide pod->service hairpinning.";
      };

      enablePodSNAT = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SNAT'ing of pod egress traffic.";
      };

      peerRouters = mkOption {

        type = types.listOf (types.submodule {

          options = {

            asn = mkOption {
              type = types.int;
              example = 32697;
              description = "ASN of the BGP peer-router.";
            };

            ip = mkOption {
              type = types.str;
              example = "10.0.0.1";
              description = "IP-address of the BGP peer-router.";
            };

            password = mkOption {
              type = types.str;
              default = "";
              description = "Password for the BGP peer-router.";
            };

          };
        });

        default = [];
        description = "List of external routers to BGP-peer with.";
      };

      cniConfig = mkOption {
        type = types.nullOr types.attrs;
        default = null;
        example = {
                    name = "k8snet";
                    type = "bridge";
                    bridge = "kube-bridge";
                    isDefaultGateway = true;
                    ipam = {
                     type = "host-local";
                    };
                  };
        description = "CNI config to be referenced by kube-router.";
      };

      mutableCniPath = mkOption {
        type = types.path;
        default = "/var/lib/kube-router";
        description = "Path for mutable cni config file.";
      };
    };
  };

  config = mkIf cfg.enable {

    environment.etc."cni/net.d/${cniConfigFileName}" = mkIf (cfg.cniConfig != null) {
      source = concatStringsSep "/" [cfg.mutableCniPath cniConfigFileName];
    };

    systemd.services.kube-router = with pkgs; {
      path = [ ipset iptables kmod ];
      description = "Kube Router";
      wantedBy = ["multi-user.target"];
      after = ["kubernetes.target"];
      requires = ["kubernetes.target"];
      inherit preStart;
      script = start;
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
