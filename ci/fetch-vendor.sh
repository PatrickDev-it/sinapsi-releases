#!/usr/bin/env bash
# The Windows CLI embeds two Node SEA bundles with `include_bytes!`
# (src/cli/src/vendored_tools.rs, rfc/039). They are not in git: they are assets of the private
# release `$VENDOR_TAG` of `$SOURCE_REPO`, and they are accepted only if they match
# src/cli/vendor/SHA256SUMS, which is in git. A mismatch stops the build before cargo runs.
#
# Usage: GH_TOKEN=... SOURCE_REPO=... VENDOR_TAG=... bash ci/fetch-vendor.sh <source checkout>
set -euo pipefail

vendor="$1/src/cli/vendor"
[ -f "$vendor/SHA256SUMS" ] || { echo "::error::$vendor/SHA256SUMS missing: this ref predates the embedded indexers"; exit 1; }

gh release download "$VENDOR_TAG" --repo "$SOURCE_REPO" --dir "$vendor" --pattern '*.zip' --clobber
cd "$vendor"
sha256sum -c SHA256SUMS
