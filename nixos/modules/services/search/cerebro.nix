{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.cerebro;
in {
  options = {
    services.cerebro = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the Cerebro Elasticsearch GUI.
        '';
      };

      home = mkOption {
        default = "/var/lib/cerebro";
        type = types.path;
        description = ''
          The path to use as cerebro's $HOME. If the default user
          "cerebro" is configured then this is the home of the "cerebro"
          user.
        '';
      };

      package = mkOption {
        default = pkgs.cerebro;
        defaultText = "pkgs.cerebro";
        type = types.package;
        description = ''
          Package for running cerebro.
        '';
      };

      listenAddress = mkOption {
        description = "Cerebro listen address.";
        default = "0.0.0.0";
        type = types.str;
      };

      port = mkOption {
        description = "Cerebro port to listen for HTTP traffic.";
        default = 9000;
        type = types.int;
      };

      extraCmdLineOptions = mkOption {
        description = "Extra command line options for Cerebro. Could be a local config e.g. -Dconfig.file=/some/other/dir/alternate.conf";
        default = [];
        type = types.listOf types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.cerebro = {
      description = "Cerebro UI";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = ''
          ${pkgs.cerebro}/bin/cerebro \
          -Dhttp.port=${toString cfg.port} \
          -Dhttp.address=${toString cfg.listenAddress} \
          ${toString cfg.extraCmdLineOptions};
        '';
        User = "cerebro";
        WorkingDirectory = cfg.home;
      };
    };

    users = {
      groups.cerebro.gid = config.ids.gids.cerebro;
      users.cerebro = {
        description = "Cerebro daemon user";
        createHome = true;
        home = cfg.home;
        group = "cerebro";
      };
    };
  };
}
