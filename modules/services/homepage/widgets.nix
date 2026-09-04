[
  {
    search = {
      provider = "google";
      target = "_blank";
    };
  }
  {
    resources = {
      label = "system";
      cpu = true;
      memory = true;
    };
  }
  {
    resources = {
      label = "storage";
      disk = ["/data"];
    };
  }
  {
    openmeteo = {
      label = "Calgary";
      timezone = "America/Edmonton";
      latitude = "51.043674";
      longitude = "-114.09521";
      units = "metric";
    };
  }
]
