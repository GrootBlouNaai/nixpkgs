# Main scope definition for Steam packages
# This block defines the scope for generating Steam-related packages using `makeScopeWithSplicing'`.
# It includes various Steam-related packages such as `steam-runtime`, `steam`, `steam-fhsenv`, and `steamcmd`.
# The scope is created with splicing to ensure that all dependencies are correctly built and linked.
{ makeScopeWithSplicing', generateSplicesForMkScope
, stdenv, buildFHSEnv, pkgsi686Linux, mesa-demos
}:

let
  # Function to generate Steam packages
  # This function defines the set of Steam-related packages and their dependencies.
  # It uses `callPackage` to import and build each package from its respective Nix file.
  steamPackagesFun = self: let
    inherit (self) callPackage;
  in rec {
    # Determine the Steam architecture based on the host platform
    # This is necessary to correctly build and link 32-bit and 64-bit libraries.
    steamArch = if stdenv.hostPlatform.system == "x86_64-linux" then "amd64"
                else if stdenv.hostPlatform.system == "i686-linux" then "i386"
                else throw "Unsupported platform: ${stdenv.hostPlatform.system}";

    # Steam runtime environment
    # This package includes the runtime environment required by Steam to run games and applications.
    steam-runtime = callPackage ./runtime.nix { };

    # Wrapped Steam runtime environment
    # This package wraps the Steam runtime environment to ensure it is correctly set up for use.
    steam-runtime-wrapped = callPackage ./runtime-wrapped.nix { };

    # Steam client package
    # This package includes the Steam client application and its dependencies.
    steam = callPackage ./steam.nix { };

    # Steam FHS environment
    # This package sets up a FHS (File Hierarchy Standard) environment for running Steam and its dependencies.
    # It includes 32-bit and 64-bit libraries, as well as additional tools and utilities.
    steam-fhsenv = callPackage ./fhsenv.nix {
      mesa-demos-i686 =
        if self.steamArch == "amd64"
        then pkgsi686Linux.mesa-demos
        else mesa-demos;
      steam-runtime-wrapped-i686 =
        if self.steamArch == "amd64"
        then pkgsi686Linux.steamPackages.steam-runtime-wrapped
        else null;
      inherit buildFHSEnv;
    };

    # Smaller Steam FHS environment
    # This package is a variant of `steam-fhsenv` that excludes game-specific libraries to reduce size.
    steam-fhsenv-small = steam-fhsenv.override { withGameSpecificLibraries = false; };

    # Steam FHS environment without Steam client
    # This package sets up the FHS environment without including the Steam client itself.
    # It is useful for building and testing dependencies without the full Steam client.
    steam-fhsenv-without-steam = steam-fhsenv.override { steam = null; };

    # SteamCMD package
    # This package includes the Steam command-line interface (SteamCMD) for managing and updating Steam games.
    steamcmd = callPackage ./steamcmd.nix { };
  };

# Create the scope with splicing
# This block uses `makeScopeWithSplicing'` to create the scope for the Steam packages.
# It ensures that all dependencies are correctly spliced and built.
in makeScopeWithSplicing' {
  otherSplices = generateSplicesForMkScope "steamPackages";
  f = steamPackagesFun;
}
