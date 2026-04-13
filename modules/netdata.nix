{ config, ... }:

{
  sops.secrets.netdata_telegram_bot_token = {
    key = "netdata/telegram_bot_token";
    owner = "netdata";
    group = "netdata";
    mode = "0440";
  };

  sops.secrets.netdata_telegram_chat_id = {
    key = "netdata/telegram_chat_id";
    owner = "netdata";
    group = "netdata";
    mode = "0440";
  };

  sops.templates.netdata-health-alarm-notify-conf = {
    path = "/etc/netdata/health_alarm_notify.conf";
    owner = "netdata";
    group = "netdata";
    mode = "0440";
    content = ''
      SEND_TELEGRAM="YES"
      TELEGRAM_BOT_TOKEN="${config.sops.placeholder.netdata_telegram_bot_token}"
      DEFAULT_RECIPIENT_TELEGRAM="${config.sops.placeholder.netdata_telegram_chat_id}"
    '';
  };

  services.netdata = {
    enable = true;
  };
}
