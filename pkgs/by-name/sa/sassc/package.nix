{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  libsass,
}:

stdenv.mkDerivation rec {
  pname = "sassc";
  version = "3.6.2"; # also check libsass for updates

  src = fetchFromGitHub {
    owner = "sass";
    repo = "sassc";
    rev = version;
    sha256 = "sha256-jcs3+orRqKt9C3c2FTdeaj4H2rBP74lW3HF8CHSm7lQ=";
  };

  postPatch = ''
    export SASSC_VERSION=${version}
  '';

  nativeBuildInputs = [ autoreconfHook ];

  buildInputs = [ libsass ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Front-end for libsass";
    homepage = "https://github.com/sass/sassc/";
    license = licenses.mit;
    mainProgram = "sassc";
    maintainers = with maintainers; [
      codyopel
      pjones
    ];
    platforms = platforms.unix;
  };
}
