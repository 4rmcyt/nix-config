{ ... }: {
  services.changedetection-io = {
    enable = true;
    baseURL = "https://changedetection.example.com";
  };
}