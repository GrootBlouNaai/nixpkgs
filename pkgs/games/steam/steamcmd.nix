# SteamCMD package
# This package includes the Steam command-line tools (SteamCMD) for managing and updating Steam games.
# It is fetched from the Steam repository and includes various scripts and configurations required by SteamCMD.
{ lib, stdenv, fetchurl, steam-run, bash, coreutils
, steamRoot ? "~/.local/share/Steam"
}:

stdenv.mkDerivation {
  # Package name
  pname = "steamcmd";

  # Version of the SteamCMD tools
  # This version is determined by the mtime of the source tarball.
  version = "20180104";

  # Source URL and hash for the SteamCMD tarball
  src = fetchurl {
    url = "https://web.archive.org/web/20240521141411/https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz";
    hash = "sha256-zr8ARr/QjPRdprwJSuR6o56/QVXl7eQTc7V5uPEHHnw=";
  };

  # Pre-unpack commands
  # This section ensures that the source tarball is unpacked into a single top-level directory.
  preUnpack = ''
    mkdir $name
    cd $name
    sourceRoot=.
  '';

  # Build inputs required for the build process
  buildInputs = [ bash steam-run ];

  # Disable the build phase as the source tarball is pre-built
  dontBuild = true;

  # Install phase commands
  # This section installs the SteamCMD scripts and binaries into the correct directories.
  # It also substitutes variables in the `steamcmd.sh` script to ensure correct paths and dependencies.
  installPhase = ''
    mkdir -p $out/share/steamcmd/linux32
    install -Dm755 steamcmd.sh $out/share/steamcmd/steamcmd.sh
    install -Dm755 linux32/* $out/share/steamcmd/linux32

    mkdir -p $out/bin
    substitute ${./steamcmd.sh} $out/bin/steamcmd \
      --subst-var out \
      --subst-var-by coreutils ${coreutils} \
      --subst-var-by steamRoot "${steamRoot}" \
      --subst-var-by steamRun ${steam-run}
    chmod 0755 $out/bin/steamcmd
  '';

  # Metadata for the package
  meta = with lib; {
    homepage = "https://developer.valvesoftware.com/wiki/SteamCMD";
    description = "Steam command-line tools";
    mainProgram = "steamcmd";
    platforms = platforms.linux;
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [ tadfisher ];
  };
}
