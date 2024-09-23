# Steam runtime wrapped package
# This package wraps the Steam runtime environment to ensure it is correctly set up for use.
# It includes various libraries and binaries required by Steam and its dependencies.
{ stdenv, steamArch, lib, perl, pkgs, steam-runtime
, runtimeOnly ? false
}:

let
  # Override packages to include additional libraries if `runtimeOnly` is false
  # These packages are necessary for the full functionality of Steam and its dependencies.
  overridePkgs = lib.optionals (!runtimeOnly) (with pkgs; [
    libgpg-error
    libpulseaudio
    alsa-lib
    openalSoft
    libva1
    libvdpau
    vulkan-loader
    gcc.cc.lib
    nss
    nspr
    xorg.libxcb
  ]);

  # Combine override packages with the Steam runtime
  allPkgs = overridePkgs ++ [ steam-runtime ];

  # Determine the GNU architecture based on the Steam architecture
  # This is necessary to correctly build and link 32-bit and 64-bit libraries.
  gnuArch = if steamArch == "amd64" then "x86_64-linux-gnu"
            else if steamArch == "i386" then "i386-linux-gnu"
            else throw "Unsupported architecture";

  # Define the paths for libraries and binaries
  libs = [ "lib/${gnuArch}" "lib" "usr/lib/${gnuArch}" "usr/lib" ];
  bins = [ "bin" "usr/bin" ];

in stdenv.mkDerivation {
  # Name of the derivation
  name = "steam-runtime-wrapped";

  # Native build inputs required for the build process
  nativeBuildInputs = [ perl ];

  # Builder script to use for the derivation
  builder = ./build-wrapped.sh;

  # Passthru attributes for additional information
  passthru = {
    inherit gnuArch libs bins overridePkgs;
    arch = steamArch;
  };

  # Install phase commands
  # This phase builds the directory structure for the runtime environment,
  # copying or linking the necessary libraries and binaries into the correct paths.
  installPhase = ''
    buildDir "${toString libs}" "${toString (map lib.getLib allPkgs)}"
    buildDir "${toString bins}" "${toString (map lib.getBin allPkgs)}"
  '';
}
