# Disable the dwarfs `os_access_generic.set_thread_affinity` test globally.
#
# CTest registers each gtest case individually and invokes it with an explicit
# `--gtest_filter`, which overrides the package's negative env GTEST_FILTER, so
# filtering the test out that way does not work. Instead rename the test to a
# gtest `DISABLED_` case at the source level; gtest always skips those.
#
# The test fails in the Nix sandbox because setting CPU affinity is not
# permitted there. Applying this as an overlay ensures every consumer of
# `dwarfs` (including packages that depend on it) gets the fixed build.
_final: prev: {
  dwarfs = prev.dwarfs.overrideAttrs (oldAttrs: {
    postPatch =
      (oldAttrs.postPatch or "")
      + ''
        substituteInPlace test/os_access_generic_test.cpp \
          --replace-fail "TEST(os_access_generic, set_thread_affinity)" \
                         "TEST(os_access_generic, DISABLED_set_thread_affinity)"
      '';
  });
}
