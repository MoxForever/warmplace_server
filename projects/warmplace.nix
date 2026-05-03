{ lib, ... }:

{
  services.postgresql = {
    ensureDatabases = [ "warmplace" ];
    ensureUsers = [
      {
        name = "warmplace";
        ensureDBOwnership = true;
      }
    ];
  };

  services.redis.servers.warmplace = {
    enable = true;
    port = 6381;
    settings = {
      bind = lib.mkForce "0.0.0.0";
      "protected-mode" = "no";
    };
  };

  docker-deploy."warmplace" = {
    repo = "https://github.com/WarmYaeShop/warmplace_shop";
    branch = "main";
    dockerfile = "docker/Dockerfile";
    ports = [ "8001:80" ];
    volumes = [
      "/home/deploy/warmplace-data:/usr/src/app/data"
      "/home/deploy/price_sheets:/usr/src/app/price_sheets:rw"
    ];
  };

  services.nginx.virtualHosts."warmplace.moxforever.me" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://localhost:8001/";
    };
  };
}
