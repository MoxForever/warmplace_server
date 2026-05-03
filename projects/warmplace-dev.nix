{ lib, ... }:

{
  services.postgresql = {
    ensureDatabases = [ "warmplace-dev" ];
    ensureUsers = [
      {
        name = "warmplace-dev";
        ensureDBOwnership = true;
      }
    ];
  };

  services.redis.servers."warmplace-dev" = {
    enable = true;
    port = 6379;
    settings = {
      bind = lib.mkForce "0.0.0.0";
      "protected-mode" = "no";
    };
  };

  docker-deploy."warmplace-dev" = {
    repo = "https://github.com/WarmYaeShop/warmplace_shop";
    branch = "dev";
    dockerfile = "docker/Dockerfile";
    ports = [ "8001:80" ];
  };

  services.nginx.virtualHosts."test-wy.moxforever.me" = {
    forceSSL = true;
    enableACME = true;

    locations."/telegram/" = {
      proxyPass = "http://localhost:8005/telegram/";
    };

    locations."/service/" = {
      proxyPass = "http://localhost:8005/service/";
    };
  };
}
