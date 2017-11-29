{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.elasticsearch;

  es5 = builtins.compareVersions (builtins.parseDrvName cfg.package.name).version "5" >= 0;

  esConfig = ''
    network.host: ${cfg.listenAddress}
    cluster.name: ${cfg.cluster_name}

    ${if es5 then ''
      http.port: ${toString cfg.port}
      transport.tcp.port: ${toString cfg.tcp_port}
      path.logs: ${toString cfg.dataDir}/logs
      path.data: ${toString cfg.dataDir}
    '' else ''
      network.port: ${toString cfg.port}
      network.tcp.port: ${toString cfg.tcp_port}
      # TODO: find a way to enable security manager
      security.manager.enabled: false
    ''}

    ${cfg.extraConf}
  '';

  configDir = pkgs.buildEnv {
    name = "elasticsearch-config";
    paths = [
      (pkgs.writeTextDir "elasticsearch.yml" esConfig)
      (pkgs.writeTextDir "jvm.options" cfg.jvmOptions)
      (if es5 then (pkgs.writeTextDir "log4j2.properties" cfg.logging)
              else (pkgs.writeTextDir "logging.yml" cfg.logging))
    ];
    # Elasticsearch 5.x won't start when the scripts directory does not exist
    postBuild = if es5 then "${pkgs.coreutils}/bin/mkdir -p $out/scripts" else "";
  };

  esPlugins = pkgs.buildEnv {
    name = "elasticsearch-plugins";
    paths = cfg.plugins;
    # Elasticsearch 5.x won't start when the plugins directory does not exist
    postBuild = if es5 then "${pkgs.coreutils}/bin/mkdir -p $out/plugins" else "";
  };

in {

  ###### interface

  options.services.elasticsearch = {
    enable = mkOption {
      description = "Whether to enable elasticsearch.";
      default = false;
      type = types.bool;
    };

    package = mkOption {
      description = "Elasticsearch package to use.";
      default = pkgs.elasticsearch2;
      defaultText = "pkgs.elasticsearch2";
      type = types.package;
    };

    listenAddress = mkOption {
      description = "Elasticsearch listen address.";
      default = "127.0.0.1";
      type = types.str;
    };

    port = mkOption {
      description = "Elasticsearch port to listen for HTTP traffic.";
      default = 9200;
      type = types.int;
    };

    tcp_port = mkOption {
      description = "Elasticsearch port for the node to node communication.";
      default = 9300;
      type = types.int;
    };

    cluster_name = mkOption {
      description = "Elasticsearch name that identifies your cluster for auto-discovery.";
      default = "elasticsearch";
      type = types.str;
    };

    heapSize = mkOption {
      description = "Value for -Xms and -Xmx, eg. 1g means -Xms1g -Xmx1g";
      default = "1g";
      type = types.str;
    };

    extraConf = mkOption {
      description = "Extra configuration for elasticsearch.";
      default = "";
      type = types.str;
      example = ''
        node.name: "elasticsearch"
        node.master: true
        node.data: false
        index.number_of_shards: 5
        index.number_of_replicas: 1
      '';
    };

    logging = mkOption {
      description = "Elasticsearch logging configuration.";
      default =
        if es5 then ''
          logger.action.name = org.elasticsearch.action
          logger.action.level = info

          appender.console.type = Console
          appender.console.name = console
          appender.console.layout.type = PatternLayout
          appender.console.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] %marker%m%n

          rootLogger.level = info
          rootLogger.appenderRef.console.ref = console
        '' else ''
          rootLogger: INFO, console
          logger:
            action: INFO
            com.amazonaws: WARN
          appender:
            console:
              type: console
              layout:
                type: consolePattern
                conversionPattern: "[%d{ISO8601}][%-5p][%-25c] %m%n"
        '';
      type = types.str;
    };

    jvmOptions = mkOption {
      type = types.string;
      description = "JVM options. Defaults to the distributed jvm.options file";
      default = ''
        ## JVM configuration
        
        ################################################################
        ## IMPORTANT: JVM heap size
        ################################################################
        ##
        ## You should always set the min and max JVM heap
        ## size to the same value. For example, to set
        ## the heap to 4 GB, set:
        ##
        ## -Xms4g
        ## -Xmx4g
        ##
        ## See https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html
        ## for more information
        ##
        ################################################################
        
        # Xms represents the initial size of total heap space
        # Xmx represents the maximum size of total heap space
        
        -Xms${cfg.heapSize}
        -Xmx${cfg.heapSize}
        
        ################################################################
        ## Expert settings
        ################################################################
        ##
        ## All settings below this section are considered
        ## expert settings. Don't tamper with them unless
        ## you understand what you are doing
        ##
        ################################################################
        
        ## GC configuration
        -XX:+UseConcMarkSweepGC
        -XX:CMSInitiatingOccupancyFraction=75
        -XX:+UseCMSInitiatingOccupancyOnly
        
        ## optimizations
        
        # pre-touch memory pages used by the JVM during initialization
        -XX:+AlwaysPreTouch
        
        ## basic
        
        # force the server VM
        -server
        
        # explicitly set the stack size
        -Xss1m
        
        # set to headless, just in case
        -Djava.awt.headless=true
        
        # ensure UTF-8 encoding by default (e.g. filenames)
        -Dfile.encoding=UTF-8
        
        # use our provided JNA always versus the system one
        -Djna.nosys=true
        
        # turn off a JDK optimization that throws away stack traces for common
        # exceptions because stack traces are important for debugging
        -XX:-OmitStackTraceInFastThrow
        
        # flags to configure Netty
        -Dio.netty.noUnsafe=true
        -Dio.netty.noKeySetOptimization=true
        -Dio.netty.recycler.maxCapacityPerThread=0
        
        # log4j 2
        -Dlog4j.shutdownHookEnabled=false
        -Dlog4j2.disable.jmx=true
        
        ## heap dumps
        
        # generate a heap dump when an allocation from the Java heap fails
        # heap dumps are created in the working directory of the JVM
        -XX:+HeapDumpOnOutOfMemoryError
        
        # specify an alternative path for heap dumps
        # ensure the directory exists and has sufficient space
        #-XX:HeapDumpPath=/heap/dump/path
        
        ## GC logging
        
        #-XX:+PrintGCDetails
        #-XX:+PrintGCTimeStamps
        #-XX:+PrintGCDateStamps
        #-XX:+PrintClassHistogram
        #-XX:+PrintTenuringDistribution
        #-XX:+PrintGCApplicationStoppedTime
        
        # log GC status to a file with time stamps
        # ensure the directory exists
        #-Xloggc:''${loggc}
        
        # By default, the GC log file will not rotate.
        # By uncommenting the lines below, the GC log file
        # will be rotated every 128MB at most 32 times.
        #-XX:+UseGCLogFileRotation
        #-XX:NumberOfGCLogFiles=32
        #-XX:GCLogFileSize=128M
      '';
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/elasticsearch";
      description = ''
        Data directory for elasticsearch.
      '';
    };

    extraCmdLineOptions = mkOption {
      description = "Extra command line options for the elasticsearch launcher.";
      default = [];
      type = types.listOf types.str;
    };

    extraJavaOptions = mkOption {
      description = "Extra command line options for Java.";
      default = [];
      type = types.listOf types.str;
      example = [ "-Djava.net.preferIPv4Stack=true" ];
    };

    plugins = mkOption {
      description = "Extra elasticsearch plugins";
      default = [];
      type = types.listOf types.package;
    };

  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.elasticsearch = {
      description = "Elasticsearch Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.inetutils ];
      environment = {
        ES_HOME = cfg.dataDir;
        ES_PATH_CONF = configDir;
        ES_JAVA_OPTS = toString ([ "-Des.path.conf=${configDir}" ] ++ cfg.extraJavaOptions);
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/elasticsearch ${toString cfg.extraCmdLineOptions}";
        User = "elasticsearch";
        PermissionsStartOnly = true;
        LimitNOFILE = "1024000";
      };
      preStart = ''
        ${optionalString (!config.boot.isContainer) ''
          # Only set vm.max_map_count if lower than ES required minimum
          # This avoids conflict if configured via boot.kernel.sysctl
          if [ `${pkgs.procps}/bin/sysctl -n vm.max_map_count` -lt 262144 ]; then
            ${pkgs.procps}/bin/sysctl -w vm.max_map_count=262144
          fi
        ''}

        mkdir -m 0700 -p ${cfg.dataDir}

        # Install plugins
        ln -sfT ${esPlugins}/plugins ${cfg.dataDir}/plugins
        ln -sfT ${cfg.package}/lib ${cfg.dataDir}/lib
        ln -sfT ${cfg.package}/modules ${cfg.dataDir}/modules
        if [ "$(id -u)" = 0 ]; then chown -R elasticsearch ${cfg.dataDir}; fi
      '';
    };

    environment.systemPackages = [ cfg.package ];

    users = {
      groups.elasticsearch.gid = config.ids.gids.elasticsearch;
      users.elasticsearch = {
        uid = config.ids.uids.elasticsearch;
        description = "Elasticsearch daemon user";
        home = cfg.dataDir;
        group = "elasticsearch";
      };
    };
  };
}
