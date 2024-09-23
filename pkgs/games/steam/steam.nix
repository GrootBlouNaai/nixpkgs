# Steam original package
# This package includes the original Steam client and its associated files.
# It is fetched from the Steam repository and includes various scripts and configurations required by Steam.
{ lib, stdenv, fetchurl, runtimeShell, traceDeps ? false, bash }:

stdenv.mkDerivation (finalAttrs: {
  # Package name
  pname = "steam-original";

  # Version of the Steam client
  version = "1.0.0.81";

  # Source URL and hash for the Steam client tarball
  src = fetchurl {
    # Use archive URL to ensure the tarball does not 404 on a new release
    url = "https://repo.steampowered.com/steam/archive/stable/steam_${finalAttrs.version}.tar.gz";
    hash = "sha256-Gia5182s4J4E3Ia1EeC5kjJX9mSltsr+b+1eRtEXtPk=";
  };

  # Make flags to set the installation destination and prefix
  makeFlags = [ "DESTDIR=$(out)" "PREFIX=" ];

  # Post-installation commands
  # This section includes additional commands to be executed after the main installation process.
  # It handles the installation of udev rules, the `steamdeps` script, and the `steam.desktop` file.
  postInstall =
  let
    # Log file for tracing dependencies
    traceLog = "/tmp/steam-trace-dependencies.log";
  in ''
    # Remove the original `steamdeps` script
    rm $out/bin/steamdeps

    # Optionally install a custom `steamdeps` script to trace dependencies
    ${lib.optionalString traceDeps ''
      cat > $out/bin/steamdeps <<EOF
      #!${runtimeShell}
      echo \$1 >> ${traceLog}
      cat \$1 >> ${traceLog}
      echo >> ${traceLog}
      EOF
      chmod +x $out/bin/steamdeps
    ''}

    # Install udev rules
    mkdir -p $out/etc/udev/rules.d/
    cp ./subprojects/steam-devices/*.rules $out/etc/udev/rules.d/
    substituteInPlace $out/etc/udev/rules.d/60-steam-input.rules \
      --replace "/bin/sh" "${bash}/bin/bash"

    # Install the `steam.desktop` file
    # This file is used to create a desktop entry for Steam.
    rm $out/share/applications/steam.desktop
    sed -e 's,/usr/bin/steam,steam,g' steam.desktop > $out/share/applications/steam.desktop
  '';

  # Passthru attributes for additional functionality
  passthru.updateScript = ./update-bootstrap.py;

  # Metadata for the package
  meta = with lib; {
    description = "Digital distribution platform";
    longDescription = ''
      Steam is a video game digital distribution service and storefront from Valve.

      To install on NixOS, please use the option `programs.steam.enable = true`.
    '';
    homepage = "https://store.steampowered.com/";
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [ jagajaga ];
    mainProgram = "steam";
  };
})
