final: prev: {
  dwarfs = (prev.dwarfs.override {
    boost = prev.boost188;
  }).overrideAttrs (old: {
    doCheck = false;
    cmakeFlags = (old.cmakeFlags or []) ++ [ "-DWITH_TESTS=OFF" ];
  });
}
