{ lib
, stdenv
, bash
, meson
, ninja
, pkg-config
, glib
, libdrm
, libepoxy
, libvncserver
, libxkbcommon
, systemd
}:

stdenv.mkDerivation rec {
  pname = "reframe";
  version = "1.3.1";

  src = ../.;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    glib
    libdrm
    libepoxy
    libvncserver
    libxkbcommon
    systemd
  ];

  mesonBuildType = "release";
  strictDeps = true;

  mesonFlags = [
    "-Dsystemd=true"
    "-Dusername=reframe"
    "-Dconfdir=${placeholder "out"}/etc/reframe"
    "-Dsystemunitdir=${placeholder "out"}/lib/systemd/system"
    "-Dsysusersdir=${placeholder "out"}/lib/sysusers.d"
  ];

  postPatch = ''
    substituteInPlace meson_post_install.sh \
      --replace "systemd-sysusers" "true" \
      --replace "systemctl daemon-reload" "true"
    substituteInPlace meson_post_install.sh \
      --replace "#!/bin/bash" "#!${bash}/bin/bash"
    substituteInPlace dists/reframe-server@.service.in \
      --replace '--config=@confdir@/%i.conf' '--config=/etc/reframe/%i.conf'
    substituteInPlace dists/reframe-streamer@.service.in \
      --replace '--config=@confdir@/%i.conf' '--config=/etc/reframe/%i.conf'
  '';

  doCheck = true;
  checkPhase = ''
    meson test --print-errorlogs
  '';

  meta = with lib; {
    description = "DRM/KMS based remote desktop for Linux";
    homepage = "https://github.com/AlynxZhou/reframe";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "reframe-server";
  };
}
