{
  lib,
  fetchFromGitHub,
  rustPlatform
}: let 
  src = fetchFromGitHub {
    owner = "ProtonVPN";
    repo = "python-proton-vpn-local-agent";
    rev = "a7c706bfce46cdf7fc912faad878aba22dc6aad9";
    hash = "sha256-ygIAwHP5HLj3tjl8OyNRrid19SFyBmS6rsCofqsZPMk=";
  };

  meta = {
    description = "Implementation of the proton-vpn-killswitch interface using Network Manager";
    homepage = "https://github.com/ProtonVPN/python-proton-vpn-killswitch-network-manager";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ sebtm ];
  };

  pythonBindings = rustPlatform.buildRustPackage {
    inherit src meta;

    pname = "proton-vpn-local-agent";
    version = "unstable-20240917";

    cargoHash = "sha256-/DJGf1tD6heSzQszGwyzOmaCa2oo1x09FVRlQK8ZyHI=";

    sourceRoot = "${src.name}/python-proton-vpn-local-agent";
  };


in rustPlatform.buildRustPackage {
  inherit src meta;

  pname = "proton-vpn-local-agent";
  version = "unstable-20240917";
  cargoHash = "sha256-K0tV1JRKt58xHbMkTG8NuRBzj9yVwXHU+uhPtg+dnsU=";

  sourceRoot = "${src.name}/local_agent_rs";

  cargoBuildFlags = [
    "--release"
  ];

  installPhase = ''
    ls -al target/release/
    mv target/release/ $out
  '';
}
