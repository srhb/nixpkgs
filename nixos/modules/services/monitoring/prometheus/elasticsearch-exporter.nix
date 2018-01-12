# prometheus elasticsearch exporter
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.prometheus.elasticsearchExporter;
in {
  options = {
    services.prometheus.elasticsearchExporter = {
      enable = mkEnableOption "prometheus elasticsearch exporter";

      es.all = mkOption {
        type = types.bool;
        default = false;
        description = "Export stats for all nodes in the cluster";
      };
      es.ca = mkOption {
        description = "Path to PEM file that conains trusted CAs for the Elasticsearch connection";
        default = "";
        type = types.str;
      };
      es.client-cert = mkOption {
        description = "Path to PEM file that conains the corresponding cert for the private key to connect to Elasticsearch";
        default = "";
        type = types.str;
      };
      es.client-private-key = mkOption {
        description = "Path to PEM file that conains the private key for client auth when connecting to Elasticsearch";
        default = "";
        type = types.str;
      };
      es.timeout = mkOption {
        description = "Timeout for trying to get stats from Elasticsearch";
        default = "5s";
        type = types.str;
      };
      es.uri = mkOption {
        description = "HTTP API address of an Elasticsearch node";
        default = "http://localhost:9200";
        type = types.str;
      };
      web.listen-address = mkOption {
        description = "Address to listen on for web interface and telemetry";
        default = ":9108";
        type = types.str;
      };
      web.telemetry-path = mkOption {
        description = "Path under which to expose metrics";
        default = "/metrics";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {

    systemd.services.prometheus-elasticsearch-exporter = {
      description = "Prometheus exporter for elasticsearch";
      unitConfig.Documentation = "https://github.com/justwatchcom/elasticsearch_exporter";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = ''
          ${pkgs.prometheus-elasticsearch-exporter}/bin/elasticsearch_exporter \
          -es.timeout ${cfg.es.timeout} \
          -es.uri ${cfg.es.uri} \
          -web.listen-address ${cfg.web.listen-address} \
          -web.telemetry-path ${cfg.web.telemetry-path} \
          ${optionalString (cfg.es.all == "true") ''-es.all''} \
          ${optionalString (cfg.es.ca != "") ''-es.ca ${cfg.es.ca}''} \
          ${optionalString (cfg.es.client-cert != "") ''-es.client-cert ${cfg.es.client-cert}''} \
          ${optionalString (cfg.es.client-private-key != "") ''-es.client-private-key ${cfg.es.client-private-key}''} 
        '';

        User = "nobody";
        Restart = "always";
        PrivateTmp = true;
        WorkingDirectory = /tmp;
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };
  };
}
