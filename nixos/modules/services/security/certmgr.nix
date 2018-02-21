{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.certmgr;
  allSpecs = pkgs.buildEnv {
    name = "certmgr.d";
    paths = mapAttrsToList (name: value: pkgs.writeTextDir (name + ".json") (builtins.toJSON value)) cfg.declSpecs
         ++ optional (cfg.impSpecs != []) (pkgs.linkFarm "impSpecs" cfg.impSpecs);
  };

  certmgrYaml = pkgs.writeText "certmgr.yaml" (builtins.toJSON {
    dir = allSpecs;
    default_remote = cfg.defaultRemote;
    svcmgr = "systemd";
    inherit (cfg) before interval metricsPort metricsAddress;
  });
in
{
  options.services.certmgr = {
    enable = mkEnableOption "Whether to enable certmgr";

    defaultRemote = mkOption {
      type = types.str;
      default = "127.0.0.1:8888";
      description = "The default CA host:port to use";
    };

    before = mkOption {
      default = "72h";
      type = types.str;
      description = "The interval before a certificate expires to start attempting to renew it";
    };

    interval = mkOption {
      default = "30m";
      type = types.str;
      description = "How often to check certificate expirations and how often to update the cert_next_expires metric";
    };

    metricsAddress = mkOption {
      default = "127.0.0.1";
      type = types.str;
      description = "The address for the Prometheus HTTP endpoint";
    };

    metricsPort = mkOption {
      default = 8888;
      type = types.int;
      description = "The port for the Prometheus HTTP endpoint";
    };

    impSpecs = mkOption {
      default = [];
      # FIXME: Nonstorepath, must not go into store if they contain secrets
      type = with types; listOf (submodule {
        options.name = mkOption { type = str; description = "name of the symlink";   };
        options.path = mkOption { type = str; description = "target of the symlink"; };
      });
      description = "List of { name, path } to link into the specsdir imperatively.";
    };

    declSpecs = mkOption {
      default = null;
      type = with types; nullOr (attrsOf attrs); # FIXME submodule before pushing! attrsOf attrs merge in confusing ways!
      description = ''
        Certificate specs as described by:
        https://github.com/cloudflare/certmgr#certificate-specs
        These will be added to the Nix store, so they will be world readable.
      '';
    };
  };

  config = {
    systemd.services.certmgr = mkIf cfg.enable {
      description = "certmgr";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Restart = "always";
        ExecStartPre = "${pkgs.certmgr}/bin/certmgr -f ${certmgrYaml} check";
        ExecStart = "${pkgs.certmgr}/bin/certmgr -f ${certmgrYaml}";
      };
    };
  };
}
