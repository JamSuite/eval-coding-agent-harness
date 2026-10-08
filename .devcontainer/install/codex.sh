#!/bin/sh
# shellcheck shell=sh
#
# Installs the Codex CLI (`codex`) into ~/.local/bin at a pinned version.
# Idempotent: does nothing when the pinned version is already installed.
#
# npm ci also installs an older codex into node_modules/.bin, through
# promptfoo -> @openai/codex-sdk -> @openai/codex, which pins it to the SDK's
# own version. ~/.local/bin comes first on PATH, so this one wins in a shell.
set -eu

CODEX_VERSION=0.162.0
# Pinned here rather than read from the release, which comes from the same
# server as the archive and so proves nothing about tampering. Taken from the
# rust-v0.162.0 release asset digests. Update both with CODEX_VERSION.
CODEX_SHA256_AMD64=8daf67f6261161aa5939d8d42a516032d760406216779d7ce6040f242140ff73
CODEX_SHA256_ARM64=15162a9b59edf8e512b27414ec0b7db22e6424a1262b0eee8666643e0d295c2f

dest="$HOME/.local/bin"

if [ -x "$dest/codex" ] \
    && "$dest/codex" --version 2> /dev/null | grep -qx "codex-cli $CODEX_VERSION"; then
    exit 0
fi

# The static musl build has no glibc dependency, so it runs on any base image.
case $(uname -m) in
    x86_64) target=x86_64-unknown-linux-musl sha=$CODEX_SHA256_AMD64 ;;
    aarch64 | arm64) target=aarch64-unknown-linux-musl sha=$CODEX_SHA256_ARM64 ;;
    *)
        printf 'codex.sh: no codex build for %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

archive="codex-$target.tar.gz"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/$archive" \
    "https://github.com/openai/codex/releases/download/rust-v$CODEX_VERSION/$archive"
printf '%s  %s\n' "$sha" "$work/$archive" | sha256sum -c - > /dev/null
tar -xzf "$work/$archive" -C "$work" "codex-$target"
mkdir -p "$dest"
install -m 755 "$work/codex-$target" "$dest/codex"
"$dest/codex" --version
