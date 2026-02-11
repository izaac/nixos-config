{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/languages/
  languages.c = {
    enable = true;
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    # Build tools
    cmake
    ninja
    pkg-config
    gnumake

    # Debugging
    gdb
    valgrind

    # Common libraries (add/remove as needed per project)
    openssl
    zlib
    curl
    sqlite

    # Documentation
    doxygen
  ];

  # https://devenv.sh/scripts/
  scripts.build.exec = "cmake -B build -G Ninja && ninja -C build";
  scripts.clean.exec = "rm -rf build";
  scripts.test.exec = "cd build && ctest";
  scripts.debug.exec = "gdb ./build/main";

  # Environment variables for C development
  env = {
    # Ensure pkg-config can find libraries
    PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" config.packages;
  };

  enterShell = ''
    echo ""
    echo "C Development Environment"
    echo "  GCC:     $(gcc --version | head -1)"
    echo "  CMake:   $(cmake --version | head -1)"
    echo "  GDB:     $(gdb --version | head -1)"
    echo ""
    echo "Available commands:"
    echo "  build  - Build project with CMake + Ninja"
    echo "  clean  - Remove build directory"
    echo "  test   - Run tests with CTest"
    echo "  debug  - Launch GDB"
    echo ""
    echo "Included libraries: openssl, zlib, curl, sqlite"
    echo "Add more in devenv.nix packages = [ ... ]"
    echo ""
  '';
}
