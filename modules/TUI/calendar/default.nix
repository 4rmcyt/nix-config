{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    vdirsyncer
    khal
  ];

  # Secrets for Google Calendar Authentication
  # You need to add 'google_client_id' and 'google_client_secret' to your secrets/common.yaml
  sops.secrets.google_client_id = {
    sopsFile = ../../../secrets/common.yaml;
  };
  sops.secrets.google_client_secret = {
    sopsFile = ../../../secrets/common.yaml;
  };

  # Vdirsyncer Configuration (generated from secrets)
  sops.templates."vdirsyncer/config" = {
    path = "${config.xdg.configHome}/vdirsyncer/config";
    content = ''
      [general]
      status_path = "${config.home.homeDirectory}/.calendars/status"

      [pair personal_sync]
      a = "personal"
      b = "personallocal"
      collections = ["from a", "from b"]
      conflict_resolution = "a wins"
      metadata = ["color"]

      [storage personal]
      type = "google_calendar"
      token_file = "${config.xdg.configHome}/vdirsyncer/google_calendar_token"
      client_id = "${config.sops.placeholder.google_client_id}"
      client_secret = "${config.sops.placeholder.google_client_secret}"

      [storage personallocal]
      type = "filesystem"
      path = "${config.home.homeDirectory}/.calendars/Personal"
      fileext = ".ics"
    '';
  };

  # Khal Configuration
  xdg.configFile."khal/config".text = ''
    [calendars]

    [[personal]]
    path = ${config.home.homeDirectory}/.calendars/Personal/*
    type = calendar

    [locale]
    timeformat = %H:%M
    dateformat = %Y-%m-%d
    longdateformat = %Y-%m-%d
    datetimeformat = %Y-%m-%d %H:%M
    longdatetimeformat = %Y-%m-%d %H:%M
  '';
}
