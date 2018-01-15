import ./make-test.nix {
  name = "elasticsearch-exporter";

  nodes = {
    one = { config, pkgs, ... }: {
      services.prometheus.elasticsearchExporter = {
        enable = true;
      };
    };
  };

  testScript = ''
    startAll;
    $one->waitForUnit("prometheus-elasticsearch-exporter.service");
    $one->waitForOpenPort(9108);
    $one->succeed("curl -s http://127.0.0.1:9108/metrics");
  '';
}
