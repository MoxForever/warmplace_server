{ ... }:

{
  docker-deploy."cdn" = {
    repo = "https://github.com/openinary/openinary";
    branch = "main";
    rev = "86ef31d86d45f2b1475b99dd2f0e224025e9a08f";
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
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}
