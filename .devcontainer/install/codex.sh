#!/bin/sh
# shellcheck shell=sh
#
# Installs the Codex CLI (`codex`) at a pinned version: the release's full
# package unpacked under ~/.local/share/codex, with ~/.local/bin/codex linked
# to its entrypoint. Idempotent: does nothing when that link is in place.
#
# The package, not the bare codex binary: from 0.162.0 the interactive TUI
# refuses to start without the files around it (codex-package.json, bwrap, rg),
# and says "this CLI has no complete local package".
#
# Not under ~/.codex/packages/standalone, where the upstream installer puts it,
# so that codex does not treat it as its own to update past the pin.
#
# npm ci also installs an older codex into node_modules/.bin, through
# promptfoo -> @openai/codex-sdk -> @openai/codex, which pins it to the SDK's
# own version. ~/.local/bin comes first on PATH, so this one wins in a shell.
set -eu

CODEX_VERSION=0.162.0
# Pinned here rather than read from the release, which comes from the same
# server as the archive and so proves nothing about tampering. Taken from the
# rust-v0.162.0 release's codex-package_SHA256SUMS. Update both with
# CODEX_VERSION.
CODEX_SHA256_AMD64=4f573944c1d2059109d75a2f4d0cc9c03697288224a5e407717a9de98fc010c5
CODEX_SHA256_ARM64=d47a5fa21e037a1b85729b88c238ff3da8a956fc9fb5ad3976714428e7fb2bda

# The static musl build has no glibc dependency, so it runs on any base image.
case $(uname -m) in
    x86_64) target=x86_64-unknown-linux-musl sha=$CODEX_SHA256_AMD64 ;;
    aarch64 | arm64) target=aarch64-unknown-linux-musl sha=$CODEX_SHA256_ARM64 ;;
    *)
        printf 'codex.sh: no codex build for %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

dest="$HOME/.local/bin"
release="$HOME/.local/share/codex/$CODEX_VERSION-$target"

if [ "$(readlink "$dest/codex" 2> /dev/null)" = "$release/bin/codex" ] \
    && [ -f "$release/codex-package.json" ] \
    && "$dest/codex" --version 2> /dev/null | grep -qx "codex-cli $CODEX_VERSION"; then
    exit 0
fi

archive="codex-package-$target.tar.gz"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/$archive" \
    "https://github.com/openai/codex/releases/download/rust-v$CODEX_VERSION/$archive"
printf '%s  %s\n' "$sha" "$work/$archive" | sha256sum -c - > /dev/null
mkdir "$work/package"
tar -xzf "$work/$archive" -C "$work/package"
rm -rf "$release"
mkdir -p "$(dirname "$release")" "$dest"
mv "$work/package" "$release"
# -n replaces a link to an older release rather than following it; -f replaces
# a bare binary left by an earlier version of this script.
ln -sfn "$release/bin/codex" "$dest/codex"
"$dest/codex" --version
