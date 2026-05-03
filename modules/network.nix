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
      extraCommands = ''
        iptables -A nixos-fw -s 172.16.0.0/12 -p tcp --dport 5432 -j ACCEPT
        iptables -A nixos-fw -s 172.16.0.0/12 -p tcp --dport 6379 -j ACCEPT
        iptables -A nixos-fw -s 172.16.0.0/12 -p tcp --dport 6380 -j ACCEPT
        iptables -A nixos-fw -s 172.16.0.0/12 -p tcp --dport 6381 -j ACCEPT
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -s 172.16.0.0/12 -p tcp --dport 5432 -j ACCEPT || true
        iptables -D nixos-fw -s 172.16.0.0/12 -p tcp --dport 6379 -j ACCEPT || true
        iptables -D nixos-fw -s 172.16.0.0/12 -p tcp --dport 6380 -j ACCEPT || true
        iptables -D nixos-fw -s 172.16.0.0/12 -p tcp --dport 6381 -j ACCEPT || true
      '';
    };
    hostName = "warmplace";
    networkmanager.enable = true;
  };
}
