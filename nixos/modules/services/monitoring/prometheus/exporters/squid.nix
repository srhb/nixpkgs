{ config, pkgs, ... }:

let
  cfg = config.services.prometheus.exporters.squid;
in
{
  port = 9301;
  serviceOpts = {
    serviceConfig = {
      ExecStart = "${pkgs.prometheus-squid-exporter}/bin/squid-exporter";
      RestrictAddressFamilies = [
        # Need AF_UNIX to collect data
        # "AF_TCP"
      ];
    };
  };
}
