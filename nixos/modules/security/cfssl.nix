{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cfssl;
in {
  options.services.cfssl = {
    enable = mkEnableOption ''
      Whether to enable the CFSSL CA api-server.
    '';

    address = mkOption {
      default = "127.0.0.1";
      type = types.str;
      description = "Address to bind";
    };

    port = mkOption {
      default = 8888;
      type = types.int;
      description = "Port to bind";
    };

    caFile = mkOption {
      default = "file:${cfg.dataDir}/ca.pem";
      type = types.str;
      description = "CA used to sign the new certificate -- accepts '[file:]fname' or 'env:varname'";
    };

    caKeyFile = mkOption {
      default = "${cfg.dataDir}/ca-key.pem";
      type = types.str;
      description = "CA private key -- accepts '[file:]fname' or 'env:varname'";
    };

    dataDir = mkOption {
      default = "/var/lib/cfssl";
      type = types.str;
      description = "cfssl work directory";
    };
  };

  config = {
    users.extraGroups."cfssl" = {
      gid = 888;
    };
    users.extraUsers."cfssl" = {
      description = "cfssl user";
      createHome = true;
      home = cfg.dataDir;
      group = "cfssl";
      uid = 8888;
    };

    systemd.services.cfssl = mkIf cfg.enable {
      description = "CFSSL CA API server";
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        chmod 700 ${cfg.dataDir};
      '';

      serviceConfig = {
        WorkingDirectory = cfg.dataDir;
        Restart = "always";

        ExecStart = concatStringsSep " \\\n" [
          "${pkgs.cfssl}/bin/cfssl serve"
          "-address=${cfg.address}"
          "-port=${toString cfg.port}"
          "-ca=${cfg.caFile}"
          "-ca-key=${cfg.caKeyFile}"
        ];
      };
    };
  };
}
