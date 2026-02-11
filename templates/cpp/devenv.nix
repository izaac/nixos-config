{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/languages/
  languages.cplusplus = {
    enable = true;
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    # Build tools
    cmake
    ninja
    pkg-config
    gnumake

    # Clang toolchain (preferred for modern C++)
    clang
    clang-tools  # clangd (LSP), clang-format, clang-tidy
    lldb

    # Alternative: GCC toolchain
    # gcc
    # gdb

    # Analysis tools
    valgrind
    cppcheck

    # Common libraries (add/remove as needed per project)
    openssl
    zlib
    curl
    sqlite
    boost

    # Documentation
    doxygen
  ];

  # https://devenv.sh/scripts/
  scripts.build.exec = "cmake -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=1 && ninja -C build";
  scripts.clean.exec = "rm -rf build";
  scripts.test.exec = "cd build && ctest";
  scripts.debug.exec = "lldb ./build/main";
  scripts.format.exec = "find . -name '*.cpp' -o -name '*.hpp' | xargs clang-format -i";
  scripts.lint.exec = "clang-tidy src/*.cpp -- -I./include";

  # Environment variables for C++ development
  env = {
    # Ensure pkg-config can find libraries
    PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" config.packages;

    # Generate compile_commands.json for clangd
    CMAKE_EXPORT_COMPILE_COMMANDS = "1";
  };

  enterShell = ''
    echo ""
    echo "C++ Development Environment"
    echo "  Clang:   $(clang --version | head -1)"
    echo "  CMake:   $(cmake --version | head -1)"
    echo "  LLDB:    $(lldb --version | head -1)"
    echo ""
    echo "Available commands:"
    echo "  build   - Build project with CMake + Ninja"
    echo "  clean   - Remove build directory"
    echo "  test    - Run tests with CTest"
    echo "  debug   - Launch LLDB"
    echo "  format  - Format code with clang-format"
    echo "  lint    - Lint code with clang-tidy"
    echo ""
    echo "Included libraries: openssl, zlib, curl, sqlite, boost"
    echo "Add more in devenv.nix packages = [ ... ]"
    echo ""
  '';
}
