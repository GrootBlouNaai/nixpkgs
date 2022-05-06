{ lib
, stdenv
, fetchFromGitLab
, appstream-glib
, desktop-file-utils
, itstool
, meson
, ninja
, pkg-config
, python3
, wrapGAppsHook
, evolution-data-server
, feedbackd
, glibmm
, gnome-desktop
, gspell
, gtk3
, json-glib
, libgcrypt
, libhandy
, libphonenumber
, modemmanager
, olm
, pidgin
, protobuf
, sqlite
, plugins ? [ ]
}:

stdenv.mkDerivation rec {
  pname = "chatty";
  version = "0.6.3";

  src = fetchFromGitLab {
    domain = "source.puri.sm";
    owner = "Librem5";
    repo = "chatty";
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-BILi3+i7SCiK7dVbckv3cNMNyEwgKMf0ct0z/J1xysI=";
  };

  postPatch = ''
    patchShebangs build-aux/meson
  '';

  nativeBuildInputs = [
    appstream-glib
    desktop-file-utils
    itstool
    meson
    ninja
    pkg-config
    python3
    wrapGAppsHook
  ];

  buildInputs = [
    evolution-data-server
    feedbackd
    glibmm
    gnome-desktop
    gspell
    gtk3
    json-glib
    libgcrypt
    libhandy
    libphonenumber
    modemmanager
    olm
    pidgin
    protobuf
    sqlite
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PURPLE_PLUGIN_PATH : ${lib.escapeShellArg (pidgin.makePluginPath plugins)}
      ${lib.concatMapStringsSep " " (p: p.wrapArgs or "") plugins}
    )
  '';

  meta = with lib; {
    description = "XMPP and SMS messaging via libpurple and ModemManager";
    homepage = "https://source.puri.sm/Librem5/chatty";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ dotlambda tomfitzhenry ];
    platforms = platforms.linux;
  };
}
