{
  lib,
  buildDunePackage,
  dune-configurator,
  pkg-config,
  callPackage,
  ffmpeg-base ? callPackage ./base.nix { },
  ffmpeg-avutil,
  ffmpeg-avcodec,
  ffmpeg,
  stdenv,
  VideoToolbox,
}:

buildDunePackage {
  pname = "ffmpeg-swresample";

  minimalOCamlVersion = "4.08";

  inherit (ffmpeg-base) version src;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dune-configurator ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ VideoToolbox ];
  propagatedBuildInputs = [
    ffmpeg-avutil
    ffmpeg-avcodec
    ffmpeg.dev
  ];

  doCheck = true;

  meta = ffmpeg-base.meta // {
    description = "Bindings for the ffmpeg swresample library";
  };

}
