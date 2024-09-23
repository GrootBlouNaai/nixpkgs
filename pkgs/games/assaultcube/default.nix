{ lib
, stdenv
, fetchFromGitHub
, makeDesktopItem
, copyDesktopItems
, openal
, pkg-config
, libogg
, libvorbis
, SDL2
, SDL2_image
, makeWrapper
, zlib
, file
, client ? true, server ? true
}:

# Main derivation for building AssaultCube
# This derivation is responsible for building the AssaultCube game client and/or server.
# It fetches the source code from GitHub, configures the build environment, and installs
# the game binaries along with necessary assets and desktop items.

stdenv.mkDerivation rec {
  pname = "assaultcube";
  version = "1.3.0.2";

  # Source code retrieval
  # Fetches the source code from the AssaultCube GitHub repository at the specified version.
  # The source code is fetched using the `fetchFromGitHub` function, which ensures that
  # the correct revision is retrieved based on the provided version and SHA256 hash.

  src = fetchFromGitHub {
    owner = "assaultcube";
    repo  = "AC";
    rev = "v${version}";
    sha256 = "0qv339zw9q5q1y7bghca03gw7z4v89sl4lbr6h3b7siy08mcwiz9";
  };

  # Build dependencies
  # Specifies the native build inputs required for the build process.
  # These include tools like `makeWrapper` for wrapping binaries, `pkg-config` for handling
  # build configuration, and `copyDesktopItems` for copying desktop items to the system.

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    copyDesktopItems
  ];

  # Runtime dependencies
  # Specifies the runtime dependencies required for the game client and server.
  # These include libraries like `openal` for audio, `SDL2` and `SDL2_image` for graphics,
  # and `libogg` and `libvorbis` for audio encoding. The dependencies are conditionally
  # included based on whether the client or server is being built.

  buildInputs = [
    file
    zlib
  ] ++ lib.optionals client [
    openal
    SDL2
    SDL2_image
    libogg
    libvorbis
  ];

  # Build targets
  # Defines the build targets based on whether the client, server, or both are being built.
  # The `targets` variable is constructed using `lib.optionalString` to conditionally
  # include the "client" and "server" targets.

  targets = (lib.optionalString server "server") + (lib.optionalString client " client");
  makeFlags = [ "-C source/src" "CXX=${stdenv.cc.targetPrefix}c++" targets ];

  # Desktop item configuration
  # Configures the desktop item for the AssaultCube game.
  # This includes setting the name, icon, and categories for the desktop entry, which
  # will be used to create a desktop shortcut for the game.

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      desktopName = "AssaultCube";
      comment = "A multiplayer, first-person shooter game, based on the CUBE engine. Fast, arcade gameplay.";
      genericName = "First-person shooter";
      categories = [ "Game" "ActionGame" "Shooter" ];
      icon = "assaultcube";
      exec = pname;
    })
  ];

  # Game data directory
  # Specifies the directory where the game data (config and packages) will be installed.
  # This directory is used to store game assets and configurations.

  gamedatadir = "/share/games/${pname}";

  # Installation phase
  # Defines the steps to install the game binaries and assets.
  # This includes copying the game data to the specified directory, installing the client
  # and server binaries, and wrapping them with necessary environment variables and flags.

  installPhase = ''
    runHook preInstall

    bindir=$out/bin

    mkdir -p $bindir $out/$gamedatadir

    cp -r config packages $out/$gamedatadir

    if (test -e source/src/ac_client) then
      cp source/src/ac_client $bindir
      mkdir -p $out/share/applications
      install -Dpm644 packages/misc/icon.png $out/share/icons/assaultcube.png
      install -Dpm644 packages/misc/icon.png $out/share/pixmaps/assaultcube.png

      makeWrapper $out/bin/ac_client $out/bin/${pname} \
        --chdir "$out/$gamedatadir" --add-flags "--home=\$HOME/.assaultcube/v1.2next --init"
    fi

    if (test -e source/src/ac_server) then
      cp source/src/ac_server $bindir
      makeWrapper $out/bin/ac_server $out/bin/${pname}-server \
        --chdir "$out/$gamedatadir" --add-flags "-Cconfig/servercmdline.txt"
    fi

    runHook postInstall
  '';

  # Metadata
  # Provides metadata about the package, including its description, homepage, supported
  # platforms, license, and maintainers. This information is used by the package manager
  # to display details about the package and manage dependencies.

  meta = with lib; {
    description = "Fast and fun first-person-shooter based on the Cube fps";
    homepage = "https://assault.cubers.net";
    platforms = platforms.linux; # should work on darwin with a little effort.
    license = licenses.unfree;
    maintainers = with maintainers; [ darkonion0 ];
  };
}
