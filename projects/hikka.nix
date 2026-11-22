{ ... }:

{
  docker-deploy."hikka" = {
    repo = "https://github.com/Heroku-userbot/Heroku";
    branch = "master";
    dockerfile = "Dockerfile";
    command = [
      "python3"
      "-m"
      "heroku"
      "--root"
      "--no-auth"
      "--data-root=/data/sessions"
    ];
    volumes = [
      "/home/deploy/hikka-modules:/data/loaded_modules"
      "/home/deploy/hikka-data:/data/sessions"
    ];
  };

  services.nginx.virtualHosts."hikka.moxforever.me" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://localhost:8003/";
    };
  };
}
