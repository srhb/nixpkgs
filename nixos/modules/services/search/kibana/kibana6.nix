{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.kibana6;

  cfgFile = pkgs.writeText "kibana.json" (builtins.toJSON (
    (filterAttrsRecursive (n: v: v != null) ({
      path.data = "${cfg.home}/data";
      server.host = cfg.listenAddress;
      server.port = cfg.port;

      kibana.index = cfg.index;
      kibana.defaultAppId = cfg.defaultAppId;

      elasticsearch.url = cfg.elasticsearch.url;
    } // cfg.extraConfig)
  )));

in {
  options.services.kibana6 = {
    enable = mkEnableOption "enable kibana service";

    listenAddress = mkOption {
      description = "Kibana listening host";
      default = "127.0.0.1";
      type = types.str;
    };

    port = mkOption {
      description = "Kibana listening port";
      default = 5601;
      type = types.int;
    };

    index = mkOption {
      description = "Elasticsearch index to use for saving kibana config.";
      default = ".kibana";
      type = types.str;
    };

    defaultAppId = mkOption {
      description = "Elasticsearch default application id.";
      default = "discover";
      type = types.str;
    };

    elasticsearch = {
      url = mkOption {
        description = "Elasticsearch url";
        default = "http://localhost:9200";
        type = types.str;
      };
    };

    package = mkOption {
      description = "Kibana package to use";
      default = pkgs.kibana6;
      defaultText = "pkgs.kibana6";
      example = "pkgs.kibana6";
      type = types.package;
    };

    home = mkOption {
      description = "Kibana home directory";
      default = "/var/lib/kibana";
      type = types.path;
    };

    extraConfig = mkOption {
      description = "Extra configuration attributes";
      default = {};
      type = types.attrs;
    };
  };

  config = mkIf (cfg.enable) {
    systemd.services.kibana = {
      description = "Kibana Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "elasticsearch.service" ];
      environment = {
        KIBANA_HOME      = cfg.home;
        BABEL_CACHE_PATH = "${cfg.home}/.babelcache.json";
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/kibana --config ${cfgFile}";
        User = "kibana";
        WorkingDirectory = cfg.home;
      };
    };

    environment.systemPackages = [ cfg.package ];

    users.extraUsers = singleton {
      name = "kibana";
      uid = config.ids.uids.kibana;
      description = "Kibana service user";
      home = cfg.home;
      createHome = true;
    };
  };
}
