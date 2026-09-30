# AquaSKK。nixpkgs には無い (2026-08 時点で macSKK しか入っていない)。
#
# 配布物が .pkg インストーラしかないため、インストールはせず中身だけ取り出す。
# .pkg は xar アーカイブで、実体は gzip で固めた cpio (Payload) に入っている。
# 中身は ./Library/Input Methods/AquaSKK.app ただ一つ。
#
# バイナリは x86_64 と arm64 の universal で、配布元の署名 (Team ID
# FPZK4WRGW7) が付いたまま取り出せるので、Gatekeeper はそのまま通る。
{
  lib,
  stdenvNoCC,
  fetchurl,
  xar,
  cpio,
  gzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "aquaskk";
  version = "4.7.8";

  src = fetchurl {
    url = "https://github.com/codefirst/aquaskk/releases/download/${finalAttrs.version}/AquaSKK-${finalAttrs.version}.pkg";
    hash = "sha256-4MKHJP9utaAflVhaJdJaCMQpamV8o1kO4Uz9lzGN+V4=";
  };

  nativeBuildInputs = [
    xar
    cpio
    gzip
  ];

  # src は .pkg なので、既定の unpackPhase は扱えない
  unpackPhase = ''
    runHook preUnpack

    xar -xf "$src"
    gzip -dc aquaskk-pkg.pkg/Payload | cpio -i --quiet

    runHook postUnpack
  '';

  # インストール先は $out/Library/Input Methods。macOS が入力メソッドを探すのは
  # /Library/Input Methods だけなので、そこへの配置は nix/darwin/default.nix の
  # activation script が行う
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Library/Input Methods"
    cp -R "Library/Input Methods/AquaSKK.app" "$out/Library/Input Methods/"

    runHook postInstall
  '';

  meta = {
    description = "Japanese input method without morphological analysis";
    homepage = "https://github.com/codefirst/aquaskk";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
