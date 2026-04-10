{ ... }:

{
  services.nginx = {
    enable = true;
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
