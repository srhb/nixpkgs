{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.cfssl;

in


{

  ###### interface

  options = {

    services.cfssl = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the CFSSL API server 
        '';
      };
      
      address = mkOption {
        type = types.string;
        default = "127.0.0.1:8888";
        description = ''
          Address and port to listen on
        '';
      };
      
      ca = mkOption {
        type = types.path;
        description = ''
          Path to PEM-encoded certificate
        '';
      };

      caKey = mkOption {
        type = types.path;
        description = ''
          Path to PEM-encoded private key
        '';
      };
    };
    
  };
  
  
  ###### implementation
  
  config = mkIf cfg.enable {
    users = {
      extraUsers.cfssl = {
        uid = config.ids.uids.cfssl;
        group = "cfssl";
        description = "CFSSL daemon user";
      };

      extraGroups.cfssl = {
        name = "cfssl";
        gid = config.ids.gids.cfssl;
      };
    };

  
    systemd.services.cfssl =
      { description = "CFSSL API Server";
        wantedBy = [ "multi-user.target" ];
        after = [ "networking.target" ];

        path = [ pkgs.cfssl ];

        serviceConfig = {
          ExecStart = "${pkgs.cfssl}/bin/cfssl serve -ca ${toString cfg.ca} -ca-key ${toString cfg.caKey}";
          Restart = "always";
        };
      };
  };
}
