import ../make-test.nix ({ pkgs, ...} :

with import ../kubernetes/base.nix { };
let
  hostName = "machine";
  domain = "my.domain";
  fqdn = "${hostName}.${domain}";

  hosts = [ "192.168.1.1 api.${domain} master.${domain}" "192.168.1.2 node.${domain}" ];

  certs = import ../kubernetes/certs.nix {
                                          externalDomain = domain;
                                          serviceClusterIp = "10.90.0.1";
                                          kubelets = [ "master" "node" ];
                                        };

  nginxManifest = pkgs.writeText "nginx-manifest.json" (builtins.toJSON {
                   apiVersion = "apps/v1";
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

  master = import ./master.nix { inherit pkgs; hostName = "master"; ip = "10.0.2.15"; inherit domain; inherit certs; inherit hosts; sshPort=2221; };
  node = import ./node.nix { inherit pkgs; hostName = "node"; ip = "10.0.2.16"; inherit domain; inherit certs; inherit hosts; sshPort=2222; };
in
{
  nodes = { inherit master; inherit node; };

  # TODO: Test of Pod-To-Pod networking
  # TODO: Test of external peering
  # TODO: Test of service networking

  testScript = ''
    startAll

    $master->waitUntilSucceeds("kubectl get node node.my.domain | grep -w Ready");
    $master->succeed("kubectl apply -f ${nginxManifest}");
  '';
  #$node->waitUntilSucceeds("test \$(kubectl get pods | grep -c Running) == 2");

})
