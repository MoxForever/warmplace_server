{ ... }:

{
  docker-deploy."cdn" = {
    repo = "https://github.com/openinary/openinary";
    branch = "main";
    dockerfile = "docker/api.Dockerfile";
    ports = [ "8004:3000" ];
    volumes = [
      "/home/deploy/cdn-public:/app/apps/api/public"
      "/home/deploy/cdn-db:/app/data"
    ];
  };

  services.nginx.virtualHosts."cdn-wy.moxforever.me" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://localhost:8004/";
    };
  };
}
