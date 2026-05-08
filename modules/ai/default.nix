{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.ai;
in {
  options.mySystem.ai = {
    enable = mkEnableOption "AI / ML local services";

    ollama = {
      enable = mkEnableOption "Ollama local LLM server (CUDA build for NVIDIA)";
      loadModels = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["qwen2.5vl:7b" "llama3.2:3b"];
        description = ''
          Models to auto-pull on service start. Adds boot delay during first download.
          Leave empty to manage models manually with `ollama pull`.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && cfg.ollama.enable) {
    # Ollama listens on 127.0.0.1:11434 by default.
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      inherit (cfg.ollama) loadModels;
    };
  };
}
