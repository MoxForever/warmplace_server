{ lib, ... }:

{
  services.postgresql = {
    ensureDatabases = [ "yaeshop" ];
    ensureUsers = [
      {
        name = "yaeshop";
        ensureDBOwnership = true;
      }
    ];
  };

  services.redis.servers.yaeshop = {
    enable = true;
    port = 6380;
    settings = {
      bind = lib.mkForce "0.0.0.0";
      "protected-mode" = "no";
    };
  };

  docker-deploy."yaeshop" = {
    repo = "git@github.com:WarmYaeShop/yaeshop.git";
    branch = "main";
    dockerfile = "docker/Dockerfile";
    ports = [ "8002:80" ];
    volumes = [
      "/home/deploy/yaeshop-data:/usr/src/app/data"
      "/home/deploy/price_sheets:/usr/src/app/price_sheets:rw"
    ];
  };

  services.nginx.virtualHosts."yaeshop.moxforever.me" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://localhost:8002/";
    };
  };
}
