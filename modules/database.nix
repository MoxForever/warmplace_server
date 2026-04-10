{ lib, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = true;
    authentication = ''
      host all all 172.16.0.0/12 scram-sha-256
    '';
  };

  services.redis = {
    package = pkgs.redis;
  };
}
