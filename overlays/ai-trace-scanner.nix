inputs: final: _prev: {
  ai-trace-scanner = final.python3Packages.buildPythonApplication {
    pname = "ai-trace-scan";
    version = "0.8.0";
    pyproject = true;

    src = inputs.ai-trace-scanner;

    build-system = [final.python3Packages.hatchling];

    dependencies = with final.python3Packages; [
      pygments
      pathspec
    ];

    # tests require git repos — skip in nix build
    doCheck = false;

    meta = with final.lib; {
      description = "Detect AI/agentic authorship fingerprints in a codebase";
      homepage = "https://github.com/izaac/ai-trace-scanner";
      license = licenses.mit;
      mainProgram = "ai-trace-scan";
    };
  };
}
