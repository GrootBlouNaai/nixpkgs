{
  git,
  gnutar,
  gzip,
  haskell,
  haskellPackages,
  lib,
  makeBinaryWrapper,
  nixos,
  openssh,
  runc,
  runCommand,
  stdenv,
}:
let
  inherit (haskell.lib.compose) overrideCabal addBuildTools justStaticExecutables;
  inherit (lib) makeBinPath;
  bundledBins = [ gnutar gzip git openssh ] ++ lib.optional stdenv.isLinux runc;

  pkg =
    # justStaticExecutables is needed due to https://github.com/NixOS/nix/issues/2990
    overrideCabal
      (o: {
        postInstall = ''
          ${o.postInstall or ""}
          mkdir -p $out/libexec
          mv $out/bin/hercules-ci-agent $out/libexec
          makeWrapper $out/libexec/hercules-ci-agent $out/bin/hercules-ci-agent --prefix PATH : ${lib.escapeShellArg (makeBinPath bundledBins)}
        '';
      })
      (addBuildTools [ makeBinaryWrapper ] (justStaticExecutables haskellPackages.hercules-ci-agent));
in pkg.overrideAttrs (finalAttrs: o: {
    meta = o.meta // {
      position = toString ./default.nix + ":1";
    };
    passthru = o.passthru // {

      tests.help = runCommand "test-hercules-ci-agent-help" { } ''
        (${finalAttrs.finalPackage}/bin/hercules-ci-agent --help 2>&1 || true) | grep -F -- '--config'
        (${lib.getExe finalAttrs.finalPackage} --help 2>&1 || true) | grep -F -- '--config'
        touch $out
      '';

      # Does not test the package, but evaluation of the related NixOS module.
      tests.nixos-simple-config = (nixos {
        boot.loader.grub.enable = false;
        fileSystems."/".device = "bogus";
        services.hercules-ci-agent.enable = true;
        # Dummy value for testing only.
        system.stateVersion = lib.trivial.release; # TEST ONLY
      }).config.system.build.toplevel;

      tests.nixos-many-options-config = (nixos ({ pkgs, ... }: {
        boot.loader.grub.enable = false;
        fileSystems."/".device = "bogus";
        services.hercules-ci-agent = {
          enable = true;
          package = pkgs.hercules-ci-agent;
          settings = {
            workDirectory = "/var/tmp/hci";
            binaryCachesPath = "/var/keys/binary-caches.json";
            labels.foo.bar.baz = "qux";
            labels.qux = ["q" "u"];
            apiBaseUrl = "https://hci.dev.biz.example.com";
            concurrentTasks = 42;
          };
        };
        # Dummy value for testing only.
        system.stateVersion = lib.trivial.release; # TEST ONLY
      })).config.system.build.toplevel;
    };
  })
