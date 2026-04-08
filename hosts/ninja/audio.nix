_: {
  # High-fidelity PipeWire tuning for ninja's motherboard + DAC setup.
  services.pipewire = {
    wireplumber.extraConfig."95-alsa-soft-fixes" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "alsa_output.usb-Generic_USB_Audio-00.HiFi__Speaker__sink";
            }
          ];
          actions = {
            update-props = {
              "session.suspend-on-idle" = false;
              "node.pause-on-idle" = false;
              "audio.format" = "S32_LE";
              "audio.rate" = 48000;
              "api.alsa.period-size" = 1024;
              "api.alsa.headroom" = 1024;
            };
          };
        }
        {
          matches = [
            {
              "node.name" = "~alsa_input.*";
            }
            {
              "node.name" = "~alsa_output.*";
            }
          ];
          actions = {
            update-props = {
              "session.suspend-on-idle" = false;
            };
          };
        }
      ];
    };

    extraConfig.pipewire."92-high-quality" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [44100 48000 96000];
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 2048;
      };
      "context.modules" = [
        {
          name = "libpipewire-module-rt";
          args = {
            "nice.level" = -11;
            "rt.prio" = 70;
            "rt.time.soft" = 100000;
            "rt.time.hard" = 150000;
          };
          flags = ["ifexists" "nofail"];
        }
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Hifi EQ (Motherboard)";
            "media.name" = "Hifi EQ (Motherboard)";
            "filter.graph" = {
              nodes = [
                {
                  type = "builtin";
                  name = "mix_l";
                  label = "mixer";
                  control = {"Gain 1" = 0.631;};
                }
                {
                  type = "builtin";
                  name = "eq1_l";
                  label = "bq_lowshelf";
                  control = {
                    "Freq" = 32.0;
                    "Q" = 1.0;
                    "Gain" = 8.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq2_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 64.0;
                    "Q" = 1.5;
                    "Gain" = 8.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq3_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 125.0;
                    "Q" = 1.5;
                    "Gain" = 2.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq3b_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 250.0;
                    "Q" = 1.5;
                    "Gain" = 3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq4_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 500.0;
                    "Q" = 1.5;
                    "Gain" = 0.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq5_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 1000.0;
                    "Q" = 1.5;
                    "Gain" = -3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq6_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 2000.0;
                    "Q" = 1.5;
                    "Gain" = -4.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq7_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 4000.0;
                    "Q" = 1.5;
                    "Gain" = 0.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq8_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 8000.0;
                    "Q" = 1.5;
                    "Gain" = 3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq9_l";
                  label = "bq_highshelf";
                  control = {
                    "Freq" = 16000.0;
                    "Q" = 1.0;
                    "Gain" = 2.0;
                  };
                }
                {
                  type = "builtin";
                  name = "mix_r";
                  label = "mixer";
                  control = {"Gain 1" = 0.631;};
                }
                {
                  type = "builtin";
                  name = "eq1_r";
                  label = "bq_lowshelf";
                  control = {
                    "Freq" = 32.0;
                    "Q" = 1.0;
                    "Gain" = 8.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq2_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 64.0;
                    "Q" = 1.5;
                    "Gain" = 8.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq3_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 125.0;
                    "Q" = 1.5;
                    "Gain" = 2.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq3b_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 250.0;
                    "Q" = 1.5;
                    "Gain" = 3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq4_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 500.0;
                    "Q" = 1.5;
                    "Gain" = 0.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq5_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 1000.0;
                    "Q" = 1.5;
                    "Gain" = -3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq6_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 2000.0;
                    "Q" = 1.5;
                    "Gain" = -4.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq7_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 4000.0;
                    "Q" = 1.5;
                    "Gain" = 0.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq8_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 8000.0;
                    "Q" = 1.5;
                    "Gain" = 3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq9_r";
                  label = "bq_highshelf";
                  control = {
                    "Freq" = 16000.0;
                    "Q" = 1.0;
                    "Gain" = 2.0;
                  };
                }
              ];
              links = [
                {
                  output = "mix_l:Out";
                  input = "eq1_l:In";
                }
                {
                  output = "eq1_l:Out";
                  input = "eq2_l:In";
                }
                {
                  output = "eq2_l:Out";
                  input = "eq3_l:In";
                }
                {
                  output = "eq3_l:Out";
                  input = "eq3b_l:In";
                }
                {
                  output = "eq3b_l:Out";
                  input = "eq4_l:In";
                }
                {
                  output = "eq4_l:Out";
                  input = "eq5_l:In";
                }
                {
                  output = "eq5_l:Out";
                  input = "eq6_l:In";
                }
                {
                  output = "eq6_l:Out";
                  input = "eq7_l:In";
                }
                {
                  output = "eq7_l:Out";
                  input = "eq8_l:In";
                }
                {
                  output = "eq8_l:Out";
                  input = "eq9_l:In";
                }
                {
                  output = "mix_r:Out";
                  input = "eq1_r:In";
                }
                {
                  output = "eq1_r:Out";
                  input = "eq2_r:In";
                }
                {
                  output = "eq2_r:Out";
                  input = "eq3_r:In";
                }
                {
                  output = "eq3_r:Out";
                  input = "eq3b_r:In";
                }
                {
                  output = "eq3b_r:Out";
                  input = "eq4_r:In";
                }
                {
                  output = "eq4_r:Out";
                  input = "eq5_r:In";
                }
                {
                  output = "eq5_r:Out";
                  input = "eq6_r:In";
                }
                {
                  output = "eq6_r:Out";
                  input = "eq7_r:In";
                }
                {
                  output = "eq7_r:Out";
                  input = "eq8_r:In";
                }
                {
                  output = "eq8_r:Out";
                  input = "eq9_r:In";
                }
              ];
              inputs = ["mix_l:In 1" "mix_r:In 1"];
              outputs = ["eq9_l:Out" "eq9_r:Out"];
            };
            "capture.props" = {
              "node.name" = "hifi_eq_input";
              "media.class" = "Audio/Sink";
              "audio.channels" = 2;
              "audio.position" = ["FL" "FR"];
            };
            "playback.props" = {
              "node.name" = "hifi_eq_output";
              "node.passive" = true;
              "audio.channels" = 2;
              "audio.position" = ["FL" "FR"];
              "node.target" = "alsa_output.usb-Generic_USB_Audio-00.HiFi__Speaker__sink";
            };
          };
        }
      ];
      "context.rules" = [
        {
          matches = [
            {"application.name" = "ELDEN RING™";}
            {"application.name" = "cava";}
          ];
          actions = {
            update-properties = {
              "node.latency" = "1024/48000";
            };
          };
        }
      ];
    };

    extraConfig.pipewire-pulse."93-per-app-overrides" = {
      "pulse.rules" = [
        {
          matches = [
            {"application.process.binary" = "steam";}
            {"application.name" = "~.*wine.*";}
            {"application.name" = "~.*bottles.*";}
            {"application.name" = "~.*Elden Ring.*";}
          ];
          actions = {
            update-props = {
              "pulse.min.quantum" = 1024;
              "pulse.max.quantum" = 4096;
              "pulse.idle.timeout" = 0;
            };
          };
        }
      ];
    };
  };
}
