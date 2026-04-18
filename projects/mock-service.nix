{ lib, ... }:

{
  services.postgresql = {
    ensureDatabases = [ "mock_service" ];
    ensureUsers = [
      {
        name = "mock_service";
        ensureDBOwnership = true;
      }
    ];
  };

  docker-deploy."mock_service" = {
    repo = "https://github.com/WarmYaeShop/mock_service";
    branch = "main";
    dockerfile = "docker/Dockerfile";
    ports = [ "8004:80" ];
  };

  services.nginx.virtualHosts."test-wy.moxforever.me" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://localhost:8004/";
    };
  };
}
