_: {
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 6000;
      ignore-timeout = true;
      max-history = 50;
      anchor = "top-right";
      margin = "12";
      padding = "10";
      border-radius = "8";
      border-size = "1";
      icons = true;
      max-icon-size = "48";
      layer = "overlay";
      "urgency=low".default-timeout = 4000;
      "urgency=critical" = {
        default-timeout = 0;
        border-size = "2";
      };
    };
  };
}
