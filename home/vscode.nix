{ pkgs, userConfig, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium.override {
      commandLineArgs = [
        "--password-store=gnome-libsecret"
        "--ozone-platform=x11"
      ];
    };

    profiles.default = {
      # Enable the specific extension update checks
      enableExtensionUpdateCheck = true;
      enableUpdateCheck = false; # VSCodium manages its own updates or via Nix
      
      # Immutable extensions (declarative)
      extensions = with pkgs.vscode-extensions; [
        catppuccin.catppuccin-vsc
        golang.go
        ms-python.python
        ms-kubernetes-tools.vscode-kubernetes-tools
        redhat.vscode-yaml
        davidanson.vscode-markdownlint
        ms-azuretools.vscode-docker
        hashicorp.terraform
        github.copilot
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        donjayamanne.githistory
        codezombiech.gitignore
        ms-vscode-remote.remote-containers
        # Cypress isn't in nixpkgs extensions yet; install manually or use marketplace builder
        # TypeScript is built-in.
      ];

      userSettings = {
        # --- Editor Core ---
        "files.autoSave" = "afterDelay";
        "editor.renderWhitespace" = "all";
        "editor.indentSize" = "tabSize";
        "editor.detectIndentation" = false;
        "editor.minimap.autohide" = "mouseover";
        "editor.quickSuggestions" = {
          "comments" = false;
          "strings" = true;
          "other" = true;
        };
        "editor.suggestSelection" = "first";
        "workbench.editor.empty.hint" = "hidden";
        "workbench.startupEditor" = "none";
        "window.menuBarVisibility" = "compact";
        "explorer.confirmDelete" = false;
        "security.workspace.trust.untrustedFiles" = "open";

        # --- Appearance ---
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "catppuccin-mocha";
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'Droid Sans Mono', 'monospace'";
        "workbench.secondarySideBar.defaultVisibility" = "hidden";

        # --- Git ---
        "git.optimisticUpdate" = false;
        "githubPullRequests.pullBranch" = "never";

        # --- Go ---
        "go.formatTool" = "goimports";
        "go.useLanguageServer" = true;
        "go.buildFlags" = [ "-v" ];
        "go.testTimeout" = "10h";
        "go.testFlags" = [ "-v" "-count=1" "-parallel=3" ];
        "go.toolsManagement.autoUpdate" = true;
        "go.survey.prompt" = false;

        # --- Python ---
        "python.languageServer" = "Pylance";
        "python.terminal.activateEnvironment" = false;
        "[python]" = {
          "gitlens.codeLens.symbolScopes" = [ "!Module" ];
          "editor.wordBasedSuggestions" = "off";
        };

        # --- Kubernetes ---
        "vs-kubernetes" = {
           "vs-kubernetes.minikube-show-information-expiration" = "2024-06-11T16:31:33.895Z";
        };

        # --- Formatter & Languages ---
        "[typescript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[javascript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[json]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        "[dockercompose]" = {
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
          "editor.autoIndent" = "advanced";
          "editor.defaultFormatter" = "redhat.vscode-yaml";
        };
        "[github-actions-workflow]" = {
          "editor.defaultFormatter" = "redhat.vscode-yaml";
        };
                "[markdown]" = {
                  "editor.defaultFormatter" = "DavidAnson.vscode-markdownlint";
                };
                "github.copilot.nextEditSuggestions.enabled" = true;
        
                # --- Cloud & AI ---
                "geminicodeassist.project" = userConfig.geminiProject or "";
                "cloudcode.project" = userConfig.cloudCodeProject or "";
        
                "files.associations" = {
                  "*.yaml" = "yaml";
          "*.sh" = "shellscript";
          "*.tf" = "terraform";
          "*.ipynb" = "jupyter-notebook";
        };

        # --- Telemetry ---
        "telemetry.telemetryLevel" = "off";
        "redhat.telemetry.enabled" = false;
        "geminicodeassist.enableTelemetry" = false;
        "telemetry.editStats.enabled" = false;
        "telemetry.feedback.enabled" = false;

        # --- Other ---
        "update.mode" = "none";
        "update.showReleaseNotes" = false;
        "extensions.autoUpdate" = "onlyEnabledExtensions";
        "chat.commandCenter.enabled" = false;
        "accessibility.verboseChatProgressUpdates" = false;
        "workbench.commandPalette.experimental.enableNaturalLanguageSearch" = false;
        "gitProjectManager.baseProjectsFolders" = [
          "~/repos"
        ];
      };
    };
  };
}
