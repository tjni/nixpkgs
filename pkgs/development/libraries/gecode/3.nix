{ lib, stdenv, fetchpatch, fetchurl, perl }:

stdenv.mkDerivation rec {
  pname = "gecode";
  version = "3.7.3";

  src = fetchurl {
    url = "http://www.gecode.org/download/${pname}-${version}.tar.gz";
    sha256 = "0k45jas6p3cyldgyir1314ja3174sayn2h2ly3z9b4dl3368pk77";
  };

  patches = [
    (fetchpatch {
      name = "fix_no_viable_overloaded_equals";
      url = "https://github.com/Gecode/gecode/pull/74/commits/c810c96b1ce5d3692e93439f76c4fa7d3daf9fbb.patch";
      sha256 = "";
    })
  ];

  nativeBuildInputs = [ perl ];

  preConfigure = "patchShebangs configure";

  meta = with lib; {
    license = licenses.mit;
    homepage = "https://www.gecode.org";
    description = "Toolkit for developing constraint-based systems";
    platforms = platforms.all;
    maintainers = [ maintainers.manveru ];
  };
}
