{pkgs, hostName, ip, domain, services, certs, hosts, sshPort}: (


let

  fqdn = "${hostName}.${domain}";

in
{
  networking = {
    firewall.allowedTCPPortRanges = [
          { from = 179; to = 179; } # bgp
          { from = 2379; to = 2380; } # etcd
          { from = 443; to = 443; } # kubernetes.apiserver
          { from = 10250; to = 10250; } # kubelet
    ];

    firewall.trustedInterfaces = ["kube-bridge"];
    extraHosts = pkgs.lib.concatStringsSep "\n" (["127.0.0.1 ${fqdn}"] ++ hosts);
  };

  systemd.services.kube-proxy.path = [ pkgs.ipset pkgs.kmod ];
  environment.systemPackages = [ pkgs.ipvsadm pkgs.iptables pkgs.dnsutils ];

  virtualisation.docker.enable = true;
  virtualisation.memorySize = 1024;

  virtualisation.qemu.options = [ "-redir tcp:${toString sshPort}::22" ];

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

  services = services;

  security.pki.certificateFiles = [ "${certs.master}/ca.pem" "${certs.worker}/ca.pem" ];
})
