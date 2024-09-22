{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  gobject-introspection,
  setuptools,
  wrapGAppsHook3,
  dbus-python,
  packaging,
  proton-core,
  proton-keyring-linux,
  proton-keyring-linux-secretservice,
  proton-vpn-api-core,
  proton-vpn-connection,
  proton-vpn-killswitch,
  proton-vpn-killswitch-network-manager,
  proton-vpn-local-agent,
  proton-vpn-logger,
  proton-vpn-network-manager,
  proton-vpn-session,
  pycairo,
  pygobject3,
  withIndicator ? true,
  libappindicator-gtk3,
  libayatana-appindicator,
}:

buildPythonApplication rec {
  pname = "protonvpn-gui";
  version = "4.4.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ProtonVPN";
    repo = "proton-vpn-gtk-app";
    rev = "refs/tags/v${version}";
    hash = "sha256-QEdW/XXf7eW6wZLbqZbaz369vwa0xw2dmSSaxJo4E+A=";
  };

  nativeBuildInputs = [
    # Needed for the NM namespace
    gobject-introspection
    wrapGAppsHook3
  ];

  buildInputs = lib.optionals withIndicator [
    # Adds AppIndicator3 namespace
    libappindicator-gtk3
    # Adds AyatanaAppIndicator3 namespace
    libayatana-appindicator
  ];

  build-system = [
    setuptools
  ];

  dependencies = [
    dbus-python
    packaging
    proton-core
    proton-keyring-linux
    proton-keyring-linux-secretservice
    proton-vpn-api-core
    proton-vpn-connection
    proton-vpn-killswitch
    proton-vpn-killswitch-network-manager
    proton-vpn-local-agent
    proton-vpn-logger
    proton-vpn-network-manager
    proton-vpn-session
    pycairo
    pygobject3
  ];

  postInstall = ''
    mkdir -p $out/share/{applications,pixmaps}
    install -Dm 644 ${src}/rpmbuild/SOURCES/protonvpn-app.desktop $out/share/applications
    install -Dm 644 ${src}/rpmbuild/SOURCES/proton-vpn-logo.svg $out/share/pixmaps
  '';

  preCheck = ''
    # Needed for Permission denied: '/homeless-shelter'
    export HOME=$(mktemp -d)
  '';

  # Gets a segmentation fault after the widgets test
  doCheck = false;

  meta = {
    description = "Proton VPN GTK app for Linux";
    homepage = "https://github.com/ProtonVPN/proton-vpn-gtk-app";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "protonvpn-app";
    maintainers = with lib.maintainers; [ sebtm ];
  };
}
