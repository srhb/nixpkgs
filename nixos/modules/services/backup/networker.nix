{ config, pkgs, lib, ... }:

let
  cfg = config.services.networker;
  nsrRootFile = pkgs.writeTextFile {
    name = "rootNsrFile";
    text = lib.concatStringsSep "" (lib.mapAttrsToList
    (path: directives: let relPath = "." + toString path; in ''
      << ${relPath} >>
      ${lib.concatStringsSep "\n" (map (directive: "  ${directive}")
        directives)}
    '')
    cfg.nsrRoot);
  };
in

with lib;

{
  options = {
    services.networker = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables networker client nsrexecd.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/nsr";
        description = ''
          Stateful data directory.
        '';
      };

      servers = mkOption {
        type = with types; listOf string;
        description = ''
          The trusted hostnames allowed to execute commands (as root!) on this
          system.
        '';
      };

      nsrRoot = mkOption {
        type = with types; attrsOf (listOf string);
        default = { "/" = [ "+skip: * .?*" ]; };
        description = ''
          Attributes defining the /.nsr file, which specifies system-wide
          backup directives.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.networker ];

    systemd.services.networker = {
      description = "EMC Networker client";

      wantedBy = [ "multi-user.target" ];
      after    = [ "network.target" "local-fs.target" ];

      path = [ pkgs.coreutils ];

      serviceConfig = {
        Type = "forking";
        ExecStart = "-${pkgs.networker}/bin/nsrexecd${lib.concatMapStrings
          (server: " -s ${server}") cfg.servers}";
      };

      preStart = ''
        if [ ! -e "${cfg.dataDir}/.created" ]; then
          mkdir -m 0700 -p "${cfg.dataDir}"
          touch "${cfg.dataDir}/.created"
        fi

        ln -s "${cfg.dataDir}" /nsr
        ln -s "${nsrRootFile}" /.nsr
      '';

      # FIXME: Find a solution to these paths not being configurable.
      # We get rid of these whenever we stop to prevent file leakage on disk.
      # Because they're not configurable, we can't fence them behind the
      # system activation link, which makes unclean shutdowns tricky.
      postStop = ''
        rm /nsr
        rm /.nsr
      '';
    };
  };
}
