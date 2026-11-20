#!/usr/bin/env bash
# Bundles the desktop app for macOS as one universal (arm64 + x86_64) Sinapsi.app inside a .dmg.
#
# The source's tauri.conf.json keeps bundling off (Windows ships through its own installer), so
# everything macOS needs is a config overlay passed to `tauri build --config`, written here and
# never committed to the source:
#   - the owner `sinapsi` is a sidecar: Tauri puts it in Contents/MacOS, beside the app's
#     executable, which is exactly where the desktop looks for it (desktop/README.md, «Avvio»);
#   - `mainBinaryName` stays `sinapsi-desktop`: the default would be the product name `Sinapsi`,
#     and on a case-insensitive APFS volume `Sinapsi` and `sinapsi` are the same file;
#   - the notices travel in Contents/Resources/licenses, as they do in the Windows package.
#
# Tauri builds the .app only. Signing and the .dmg are three plain commands, as in any
# drag-to-Applications image: no Apple Developer ID, so the signature is ad hoc (`-`), nested
# code first and the bundle last, and nothing is notarized; the image is a folder holding the
# app and a link to /Applications, made by `hdiutil create`. Tauri's own dmg target drives
# Finder through AppleScript to lay out the window, which a headless runner has no use for.
#
# Usage: bash ci/macos-desktop.sh <source checkout> <version|""> <out dir>
# Expects target/{aarch64,x86_64}-apple-darwin/release/sinapsi already built in the checkout and
# the notices in <out dir>/../notices.
set -euo pipefail

source_dir="$(cd "$1" && pwd)"
version="${2#v}"
out="$(mkdir -p "$3" && cd "$3" && pwd)"
notices="$(cd "$out/../notices" && pwd)"
here="$(cd "$(dirname "$0")" && pwd)"
tauri_cli="@tauri-apps/cli@2.12.5"
desktop="$source_dir/desktop"
dmg="$out/sinapsi-desktop-macos-universal.dmg"

cd "$desktop"
mkdir -p sidecar licenses
# A universal build compiles each architecture on its own, and tauri-build requires the sidecar
# under that architecture's triple; the bundler then takes the universal one.
for triple in aarch64-apple-darwin x86_64-apple-darwin; do
    cp "$source_dir/target/$triple/release/sinapsi" "sidecar/sinapsi-$triple"
done
lipo -create sidecar/sinapsi-aarch64-apple-darwin sidecar/sinapsi-x86_64-apple-darwin \
    -output sidecar/sinapsi-universal-apple-darwin
cp "$notices"/* licenses/

npx --yes "$tauri_cli" icon icons/icon.svg --output .release-icons >/dev/null

version_line=""
[ -n "$version" ] && version_line="\"version\": \"$version\","
cat > tauri.release.json <<EOF
{
  $version_line
  "mainBinaryName": "sinapsi-desktop",
  "bundle": {
    "active": true,
    "targets": ["app"],
    "icon": [".release-icons/icon.icns", ".release-icons/128x128.png", ".release-icons/128x128@2x.png"],
    "externalBin": ["sidecar/sinapsi"],
    "resources": ["licenses/*"],
    "category": "DeveloperTool",
    "copyright": "Copyright (c) 2026 Patrick Simonetti",
    "macOS": { "minimumSystemVersion": "11.0" }
  }
}
EOF

bash "$here/quiet.sh" npx --yes "$tauri_cli" build --ci --target universal-apple-darwin \
    --config tauri.release.json -- --locked

app="$desktop/target/universal-apple-darwin/release/bundle/macos/Sinapsi.app"
codesign --force --sign - "$app/Contents/MacOS/sinapsi"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"

work="$(mktemp -d "${TMPDIR:-/tmp}/sinapsi-dmg.XXXXXX")"
mounted=""
cleanup() {
    if [ -n "$mounted" ]; then hdiutil detach -quiet "$mounted" || true; fi
    rm -rf "$work"
}
trap cleanup EXIT

mkdir "$work/image" "$work/mount"
ditto "$app" "$work/image/Sinapsi.app"
ln -s /Applications "$work/image/Applications"
# A hosted runner's hdiutil now and then answers "Resource busy"; the image is rebuilt whole.
for attempt in 1 2 3; do
    hdiutil create -quiet -volname Sinapsi -srcfolder "$work/image" -ov -format UDZO "$dmg" && break
    [ "$attempt" -lt 3 ] || exit 1
    sleep 10
done

# What the user will get, checked from the image itself: it mounts, the app's signature holds,
# both executables answer on every architecture this runner can execute (Intel through
# Rosetta, when installed), the notices are inside.
hdiutil verify -quiet "$dmg"
hdiutil attach -quiet -readonly -nobrowse -mountpoint "$work/mount" "$dmg"
mounted="$work/mount"
shipped="$mounted/Sinapsi.app"
codesign --verify --deep --strict "$shipped"
for exe in sinapsi-desktop sinapsi; do
    echo "$exe: $(lipo -archs "$shipped/Contents/MacOS/$exe")"
    for arch in arm64 x86_64; do
        if ! arch "-$arch" /usr/bin/true 2>/dev/null; then
            echo "  $arch: not run, this runner cannot execute $arch"
            continue
        fi
        answer="$(arch "-$arch" "$shipped/Contents/MacOS/$exe" --version)"
        echo "  $arch: $answer"
    done
done
ls "$shipped/Contents/Resources/licenses"
shasum -a 256 "$dmg"
