{
  stdenv,
  lib,
  fetchFromGitHub,
  openssl,
  nettle,
  expat,
  flex,
  libevent,
  libsodium,
  protobufc,
  hiredis,
  python ? null,
  swig,
  dns-root-data,
  pkg-config,
  makeWrapper,
  symlinkJoin,
  bison,
  nixosTests,
  #
  # By default unbound will not be built with systemd support. Unbound is a very
  # common dependency. The transitive dependency closure of systemd also
  # contains unbound.
  # Since most (all?) (lib)unbound users outside of the unbound daemon usage do
  # not need the systemd integration it is likely best to just default to no
  # systemd integration.
  # For the daemon use-case, that needs to notify systemd, use `unbound-with-systemd`.
  #
  withSystemd ? false,
  systemd ? null,
  # optionally support DNS-over-HTTPS as a server
  withDoH ? false,
  withECS ? false,
  withDNSCrypt ? false,
  withDNSTAP ? false,
  withTFO ? false,
  withRedis ? false,
  # Avoid .lib depending on lib.getLib openssl
  # The build gets a little hacky, so in some cases we disable this approach.
  withSlimLib ? stdenv.hostPlatform.isLinux && !stdenv.hostPlatform.isMusl && !withDNSTAP,
  # enable support for python plugins in unbound: note this is distinct from pyunbound
  # see https://unbound.docs.nlnetlabs.nl/en/latest/developer/python-modules.html
  withPythonModule ? false,
  # enable support for .so plugins
  withDynlibModule ? false,
  withLto ? !stdenv.hostPlatform.isStatic && !stdenv.hostPlatform.isMinGW,
  withMakeWrapper ? !stdenv.hostPlatform.isMinGW,
  libnghttp2,

  # for passthru.updateScript
  nix-update-script,
  # for passthru.tests
  gnutls,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "unbound";
  version = "1.23.0";

  src = fetchFromGitHub {
    owner = "NLnetLabs";
    repo = "unbound";
    tag = "release-${finalAttrs.version}";
    hash = "sha256-a9WNUVDy7ORB40VFUhkUxEaBho+HVNJ105AqdGDr+tI=";
  };

  outputs = [
    "out"
    "lib"
    "man"
  ]; # "dev" would only split ~20 kB

  nativeBuildInputs =
    lib.optionals withMakeWrapper [ makeWrapper ]
    ++ lib.optionals withDNSTAP [ protobufc ]
    ++ [
      pkg-config
      flex
      bison
    ]
    ++ lib.optionals withPythonModule [ swig ];

  buildInputs = [
    openssl
    nettle
    expat
    libevent
  ]
  ++ lib.optionals withSystemd [ systemd ]
  ++ lib.optionals withDoH [ libnghttp2 ]
  ++ lib.optionals withPythonModule [ python ];

  enableParallelBuilding = true;

  configureFlags = [
    "--with-ssl=${openssl.dev}"
    "--with-libexpat=${expat.dev}"
    "--with-libevent=${libevent.dev}"
    "--localstatedir=/var"
    "--sysconfdir=/etc"
    "--sbindir=\${out}/bin"
    "--with-rootkey-file=${dns-root-data}/root.key"
    "--enable-pie"
    "--enable-relro-now"
  ]
  ++ lib.optionals (!withLto) [
    "--disable-flto"
  ]
  ++ lib.optionals withSystemd [
    "--enable-systemd"
  ]
  ++ lib.optionals withPythonModule [
    "--with-pythonmodule"
  ]
  ++ lib.optionals withDynlibModule [
    "--with-dynlibmodule"
  ]
  ++ lib.optionals withDoH [
    "--with-libnghttp2=${libnghttp2.dev}"
  ]
  ++ lib.optionals withECS [
    "--enable-subnet"
  ]
  ++ lib.optionals withDNSCrypt [
    "--enable-dnscrypt"
    "--with-libsodium=${
      symlinkJoin {
        name = "libsodium-full";
        paths = [
          libsodium.dev
          libsodium.out
        ];
      }
    }"
  ]
  ++ lib.optionals withDNSTAP [
    "--enable-dnstap"
  ]
  ++ lib.optionals withTFO [
    "--enable-tfo-client"
    "--enable-tfo-server"
  ]
  ++ lib.optionals withRedis [
    "--enable-cachedb"
    "--with-libhiredis=${hiredis}"
  ];

  PROTOC_C = lib.optionalString withDNSTAP "${protobufc}/bin/protoc-c";

  # Remove references to compile-time dependencies that are included in the configure flags
  postConfigure =
    let
      inherit (builtins) storeDir;
    in
    ''
      sed -E '/CONFCMDLINE/ s;${storeDir}/[a-z0-9]{32}-;${storeDir}/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-;g' -i config.h
    '';

  doCheck = true;

  postPatch = lib.optionalString withPythonModule ''
    substituteInPlace Makefile.in \
      --replace "\$(DESTDIR)\$(PYTHON_SITE_PKG)" "$out/${python.sitePackages}"
  '';

  installFlags = [ "configfile=\${out}/etc/unbound/unbound.conf" ];

  postInstall = ''
    make unbound-event-install
  ''
  + lib.optionalString withMakeWrapper ''
    wrapProgram $out/bin/unbound-control-setup \
      --prefix PATH : ${lib.makeBinPath [ openssl ]}
  ''
  + lib.optionalString (withMakeWrapper && withPythonModule) ''
    wrapProgram $out/bin/unbound \
      --prefix PYTHONPATH : "$out/${python.sitePackages}" \
      --argv0 $out/bin/unbound
  '';

  preFixup =
    lib.optionalString withSlimLib
      # Build libunbound again, but only against nettle instead of openssl.
      # This avoids gnutls.out -> unbound.lib -> lib.getLib openssl.
      ''
        appendToVar configureFlags "--with-nettle=${nettle.dev}"
        appendToVar configureFlags "--with-libunbound-only"
        configurePhase
        buildPhase
        if [ -n "$doCheck" ]; then
            checkPhase
        fi
        installPhase
      ''
    # get rid of runtime dependencies on $dev outputs
    + ''substituteInPlace "$lib/lib/libunbound.la" ''
    + lib.concatMapStrings (
      pkg:
      lib.optionalString (
        pkg ? dev
      ) " --replace '-L${pkg.dev}/lib' '-L${pkg.out}/lib' --replace '-R${pkg.dev}/lib' '-R${pkg.out}/lib'"
    ) (builtins.filter (p: p != null) finalAttrs.buildInputs);

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex=release-(.+)"
      ];
    };
    tests = {
      inherit gnutls;
      nixos-test = nixosTests.unbound;
      nixos-test-exporter = nixosTests.prometheus-exporters.unbound;
    };
  };

  meta = {
    description = "Validating, recursive, and caching DNS resolver";
    license = lib.licenses.bsd3;
    homepage = "https://www.unbound.net";
    maintainers = with lib.maintainers; [ Scrumplex ];
    platforms = with lib.platforms; unix ++ windows;
  };
})
