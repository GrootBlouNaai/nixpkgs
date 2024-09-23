# Steam runtime package
# This package includes the official runtime environment used by Steam.
# It is fetched from the Steam repository and includes various libraries and binaries required by Steam.
{ lib, stdenv, fetchurl

# for update script
, writeShellScript, curl, nix-update
}:

stdenv.mkDerivation (finalAttrs: {

  # Package name
  pname = "steam-runtime";

  # Version of the Steam runtime
  # This version is fetched from the Steam repository and should be updated periodically.
  version = "0.20240415.84615";

  # Source URL and hash for the Steam runtime tarball
  src = fetchurl {
    url = "https://repo.steampowered.com/steamrt-images-scout/snapshots/${finalAttrs.version}/steam-runtime.tar.xz";
    hash = "sha256-C8foNnIVA+O4YwuCrIf9N6Lr/GlApPVgZsYgi+3OZUE=";
    name = "scout-runtime-${finalAttrs.version}.tar.gz";
  };

  # Build command to extract the runtime tarball into the output directory
  buildCommand = ''
    mkdir -p $out
    tar -C $out --strip=1 -x -f $src
  '';

  # Passthru attributes for additional functionality
  passthru = {
    # Update script to fetch the latest version of the Steam runtime
    # This script uses `curl` to fetch the latest version number and `nix-update` to update the package.
    updateScript = writeShellScript "update.sh" ''
      version=$(${curl}/bin/curl https://repo.steampowered.com/steamrt-images-scout/snapshots/latest-steam-client-general-availability/VERSION.txt)
      ${lib.getExe nix-update} --version "$version" steamPackages.steam-runtime
    '';
  };

  # Metadata for the package
  meta = {
    description = "Official runtime used by Steam";
    homepage = "https://github.com/ValveSoftware/steam-runtime";
    license = lib.licenses.unfreeRedistributable; # Includes NVIDIA CG toolkit
    maintainers = with lib.maintainers; [ hrdinka abbradar ];
  };
})
