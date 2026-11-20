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
#   - the notices travel in Contents/Resources/licenses, as they do in the Windows package;
#   - the signature is ad hoc (`-`): no Apple Developer ID, so no notarization.
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

cd "$desktop"
mkdir -p sidecar licenses
lipo -create \
    "$source_dir/target/aarch64-apple-darwin/release/sinapsi" \
    "$source_dir/target/x86_64-apple-darwin/release/sinapsi" \
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
    "targets": ["app", "dmg"],
    "icon": [".release-icons/icon.icns", ".release-icons/128x128.png", ".release-icons/128x128@2x.png"],
    "externalBin": ["sidecar/sinapsi"],
    "resources": ["licenses/*"],
    "category": "DeveloperTool",
    "copyright": "Copyright (c) 2026 Patrick Simonetti",
    "macOS": { "minimumSystemVersion": "11.0", "signingIdentity": "-" }
  }
}
EOF

bash "$here/quiet.sh" npx --yes "$tauri_cli" build --ci --target universal-apple-darwin \
    --config tauri.release.json -- --locked

bundle="target/universal-apple-darwin/release/bundle"
app="$bundle/macos/Sinapsi.app"
dmg="$(ls "$bundle"/dmg/*.dmg)"

# What the user will run, run once: both executables answer, both carry both architectures.
for exe in sinapsi-desktop sinapsi; do
    echo "$exe: $(lipo -archs "$app/Contents/MacOS/$exe") — $("$app/Contents/MacOS/$exe" --version)"
done
ls "$app/Contents/Resources/licenses"
codesign --verify --deep --strict "$app"

cp "$dmg" "$out/sinapsi-desktop-macos-universal.dmg"
