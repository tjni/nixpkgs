{
  lib,
  stdenv,
  fetchFromGitHub,
  pnpm_9,
  nodejs_22,
  nix-update-script,
  electron,
  pipewire,
  libpulseaudio,
  makeShellWrapper,
  makeDesktopItem,
  copyDesktopItems,
}:

let
  pnpm' = pnpm_9.override { nodejs = nodejs_22; };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "goofcord";
  version = "1.7.1";

  src = fetchFromGitHub {
    owner = "Milkshiift";
    repo = "GoofCord";
    rev = "v${finalAttrs.version}";
    hash = "sha256-fx/RKnUhXhaWVd/KYPVxr19/Q8o1ovm2TgMTcTYjE3Q=";
  };

  nativeBuildInputs = [
    pnpm'.configHook
    nodejs_22
    makeShellWrapper
    copyDesktopItems
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    libpulseaudio
    pipewire
    (lib.getLib stdenv.cc.cc)
  ];

  pnpmDeps = pnpm'.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 1;
    hash = "sha256-8dSyU9arSvISc2kDWbg/CP6L4sZjZi/Zv7TZN4ONOjQ=";
  };

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = 1;
  };

  buildPhase = ''
    runHook preBuild

    pnpm build

    npm exec electron-builder -- \
      --dir \
      -c.electronDist="${electron.dist}" \
      -c.electronVersion="${electron.version}"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/lib/goofcord"
    cp -r ./dist/*-unpacked/{locales,resources{,.pak}} "$out/share/lib/goofcord"

    install -Dm644 "build/icon.png" "$out/share/icons/hicolor/256x256/apps/goofcord.png"

    # use makeShellWrapper (instead of the makeBinaryWrapper provided by wrapGAppsHook3) for proper shell variable expansion
    # see https://github.com/NixOS/nixpkgs/issues/172583
    makeShellWrapper "${lib.getExe electron}" "$out/bin/goofcord" \
      --add-flags "$out/share/lib/goofcord/resources/app.asar" \
      "''${gappsWrapperArgs[@]}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer --enable-wayland-ime=true}}" \
      --set-default ELECTRON_IS_DEV 0 \
      --inherit-argv0

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "goofcord";
      genericName = "Internet Messenger";
      desktopName = "GoofCord";
      exec = "goofcord %U";
      icon = "goofcord";
      comment = finalAttrs.meta.description;
      keywords = [
        "discord"
        "vencord"
        "electron"
        "chat"
      ];
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
      startupWMClass = "GoofCord";
      terminal = false;
    })
  ];

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Highly configurable and privacy-focused Discord client";
    homepage = "https://github.com/Milkshiift/GoofCord";
    downloadPage = "https://github.com/Milkshiift/GoofCord";
    license = lib.licenses.osl3;
    maintainers = with lib.maintainers; [ nyabinary ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "goofcord";
  };
})
