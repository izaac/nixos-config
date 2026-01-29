final: prev: {
  sparrow = prev.sparrow.overrideAttrs (old: {
    # Use JDK 17 which is known to work well with Sparrow
    # and ensure JavaFX is enabled
    openjdk = prev.zulu17.override { enableJavaFX = true; };
    
    # The original derivation tries to extract modules from the JDK
    # which fails with some JDK builds. We can simplify this by
    # just using the full JDK.
    
    # We need to override the launcher to point to the full JDK modules
    # instead of the custom extracted ones if we skip the extraction step.
    # However, modifying the launcher script inside the derivation is tricky
    # without copying the whole thing.
    
    # Let's try a simpler approach first: just overriding the argument
    # to a JDK that has the expected structure.
    # If zulu21 failed, maybe zulu17 will work as it's an LTS release
    # often used for compatibility.
  });
}
