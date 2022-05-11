{ lib, stdenv, fetchFromGitHub, fetchpatch, bison, flex, perl, gmp, mpfr, enableGist ? true, qtbase }:

stdenv.mkDerivation rec {
  pname = "gecode";
  version = "6.2.0";

  src = fetchFromGitHub {
    owner = "Gecode";
    repo = "gecode";
    rev = "release-${version}";
    sha256 = "0b1cq0c810j1xr2x9y9996p894571sdxng5h74py17c6nr8c6dmk";
  };

  patches = [
    # This can be removed once version 6.3.0 is released.
    (fetchpatch {
      name = "fix_no_viable_overloaded_equals";
      url = "https://github.com/Gecode/gecode/pull/74/commits/c810c96b1ce5d3692e93439f76c4fa7d3daf9fbb.patch";
      sha256 = "";
    })
  ];

  enableParallelBuilding = true;
  dontWrapQtApps = true;
  nativeBuildInputs = [ bison flex ];
  buildInputs = [ perl gmp mpfr ]
    ++ lib.optional enableGist qtbase;

  meta = with lib; {
    license = licenses.mit;
    homepage = "https://www.gecode.org";
    description = "Toolkit for developing constraint-based systems";
    platforms = platforms.all;
    maintainers = [ ];
  };
}
