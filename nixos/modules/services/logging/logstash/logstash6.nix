{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.logstash6;

  lsConfig = builtins.toJSON cfg.extraConfig;

  settingsPath = pkgs.buildEnv {
    name = "logstash-settings";
    paths = [ 
      (pkgs.writeTextDir "logstash.yml" lsConfig)
      (pkgs.writeTextDir "log4j2.properties" cfg.logging)
    ];
  };

  pipelinePath = pkgs.writeText "logstash.conf" ''
    input {
      ${cfg.inputConfig}
    }

    filter {
      ${cfg.filterConfig}
    }

    output {
      ${cfg.outputConfig}
    }
  '';

in

{
  ###### interface

  options.services.logstash6 = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable logstash.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.logstash6;
      defaultText = "pkgs.logstash";
      example = literalExample "pkgs.logstash";
      description = "Logstash package to use.";
    };

    logging = mkOption {
      description = "Logstash logging configuration.";
      default = ''
        appender.console.type = Console
        appender.console.name = plain_console
        appender.console.layout.type = PatternLayout
        appender.console.layout.pattern = [%d{ISO8601}][%-5p][%-25c] %m%n
      '';
      type = types.str;
    };

    home = mkOption {
      type = types.path;
      default = "/var/lib/logstash";
      description = ''
        The Logstash home directory.
        Plugins will also have access to this path.
      '';
    };

    dataPath = mkOption {
      type = types.path;
      default = "${cfg.home}/data";
      description = ''
        The Logstash data directory.
      '';
    };

    logsPath = mkOption {
      type = types.path;
      default = "${cfg.home}/logs";
      description = ''
        The Logstash data directory.
      '';
    };

    logLevel = mkOption {
      type = types.enum [ "debug" "info" "warn" "error" "fatal" ];
      default = "warn";
      description = "Logging verbosity level.";
    };

    pipelineWorkers = mkOption {
      type = types.int;
      default = 1;
      description = "The quantity of filter workers to run.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address on which to start webserver.";
    };

    port = mkOption {
      type = types.str;
      default = "9292";
      description = "Port on which to start webserver.";
    };

    inputConfig = mkOption {
      type = types.lines;
      default = ''generator { }'';
      description = "Logstash input configuration.";
      example = ''
        # Read from journal
        pipe {
          command => "''${pkgs.systemd}/bin/journalctl -f -o json"
          type => "syslog" codec => json {}
        }
      '';
    };

    filterConfig = mkOption {
      type = types.lines;
      default = "";
      description = "logstash filter configuration.";
      example = ''
        if [type] == "syslog" {
          # Keep only relevant systemd fields
          # http://www.freedesktop.org/software/systemd/man/systemd.journal-fields.html
          prune {
            whitelist_names => [
              "type", "@timestamp", "@version",
              "MESSAGE", "PRIORITY", "SYSLOG_FACILITY"
            ]
          }
        }
      '';
    };

    outputConfig = mkOption {
      type = types.lines;
      default = ''stdout { codec => rubydebug }'';
      description = "Logstash output configuration.";
      example = ''
        redis { host => ["localhost"] data_type => "list" key => "logstash" codec => json }
        elasticsearch { }
      '';
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra configuration attributes.";
      example = {
        pipeline.batch = {
          size = 125;
          delay = 5;
        };
      };
    };
  };


  ###### implementation

  config = mkIf cfg.enable (
  mkAssert
  (!config.services.logstash.enable)
  "Multiple versions of Logstash cannot be enabled at the same time"
  {

    systemd.services.logstash = with pkgs; {
      description = "Logstash Daemon";
      wantedBy = [ "multi-user.target" ];
      environment = {
        JAVA_HOME = jre;
        LS_HOME   = cfg.home;
      };
      path = [ pkgs.bash ];
      preStart = ''
        ${pkgs.coreutils}/bin/mkdir -p       "${cfg.home}"
        ${pkgs.coreutils}/bin/chmod 700      "${cfg.home}"
        ${pkgs.coreutils}/bin/chown logstash "${cfg.home}"
      '';
      serviceConfig = {
        User = "logstash";
        PermissionsStartOnly = true;
        ExecStart = concatStringsSep " " (filter (s: stringLength s != 0) [
          "${cfg.package}/bin/logstash"
          "--path.settings ${settingsPath}"
          "--path.config   ${pipelinePath}"
          "--path.data     ${cfg.dataPath}"
          "--path.logs     ${cfg.logsPath}"
          "--log.level     ${cfg.logLevel}"
          "--pipeline.workers ${toString cfg.pipelineWorkers}"
        ]);
      };
    };

    users = {
      groups.logstash.gid = config.ids.gids.logstash;
      users.logstash = {
        uid = config.ids.uids.logstash;
        description = "Logstash daemon user";
        home = cfg.home;
        group = "logstash";
      };
    };
  });
}
