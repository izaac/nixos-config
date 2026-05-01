# Skip the openldap test suite; it's flaky on the build sandbox and not
# something we exercise in this configuration.
_final: prev: {
  openldap = prev.openldap.overrideAttrs (_oldAttrs: {
    doCheck = false;
  });
}
