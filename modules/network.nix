{ ... }:

{
  services.nginx = {
    enable = true;
    virtualHosts."_" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];

      locations."/" = {
        return = "301 https://$host$request_uri";
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "dimamolchanov2018@gmail.com";
  };
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
      ];
    };
    hostName = "warmplace";
    networkmanager.enable = true;
  };
}
