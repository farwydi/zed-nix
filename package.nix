{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  wayland,
  vulkan-loader,
  libglvnd,
  libpulseaudio,
  nodejs,
}:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  system = stdenv.hostPlatform.system;
  entry = sources.systems.${system} or (throw "zed: unsupported system ${system}");
in
stdenv.mkDerivation {
  pname = "zed";
  version = sources.version;

  # официальный бандл zed.app: bin/zed (cli) + libexec/zed-editor + свои либы в lib/
  src = fetchurl {
    url = "https://github.com/zed-industries/zed/releases/download/v${sources.version}/zed-linux-${entry.target}.tar.gz";
    hash = entry.hash;
  };

  sourceRoot = "zed.app";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    (lib.getLib stdenv.cc.cc) # libgcc_s
  ];

  # dlopen'ится в рантайме: рендер (vulkan/wayland/EGL) и звук звонков
  # ponytail: pipewire/libva не добавлены — добавить, если понадобится шаринг экрана в звонках
  runtimeDependencies = [
    wayland
    vulkan-loader
    libglvnd
    libpulseaudio
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r bin libexec lib share $out/
    runHook postInstall
  '';

  # nodejs нужен зедовским language-серверам, иначе он скачает свой glibc-бинарь node
  postFixup = ''
    wrapProgram $out/libexec/zed-editor \
      --set-default ZED_UPDATE_EXPLANATION "Installed via Nix (farwydi/zed-nix), auto-update disabled" \
      --suffix PATH : ${lib.makeBinPath [ nodejs ]}
  '';

  meta = {
    description = "Zed — high-performance, multiplayer code editor (official binary release)";
    homepage = "https://zed.dev";
    license = lib.licenses.gpl3Only;
    mainProgram = "zed";
    platforms = [ "x86_64-linux" ];
  };
}
