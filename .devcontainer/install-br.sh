#!/bin/sh
# shellcheck shell=sh
#
# Installs beads_rust (`br`), the project's only tracker, into ~/.local/bin at
# a pinned version. postCreate.sh calls it; it can also be run by hand in a
# running container. Idempotent: does nothing when the pinned version is
# already installed.
set -eu

BR_VERSION=0.7.4
# Pinned here rather than read from the release's .sha256 sidecar, which comes
# from the same server as the archive and so proves nothing about tampering.
# Taken from the v0.7.4 release sidecars. Update both with BR_VERSION.
BR_SHA256_AMD64=5263fa20f988588b88320856e7a1086505d28a2456628b85cc8f6ec51e0af732
BR_SHA256_ARM64=082d02cda1919d6b1587c0a932f5842fa510a7a18d80db0d2a85988959c4ae5b

dest="$HOME/.local/bin"

if [ -x "$dest/br" ] && "$dest/br" --version 2> /dev/null | grep -qx "br $BR_VERSION"; then
    exit 0
fi

# The static musl build has no glibc dependency, so it runs on any base image.
case $(uname -m) in
    x86_64) arch=linux_musl_amd64 sha=$BR_SHA256_AMD64 ;;
    aarch64 | arm64) arch=linux_musl_arm64 sha=$BR_SHA256_ARM64 ;;
    *)
        printf 'install-br.sh: no br build for %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

archive="br-$BR_VERSION-$arch.tar.gz"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/$archive" \
    "https://github.com/Dicklesworthstone/beads_rust/releases/download/v$BR_VERSION/$archive"
printf '%s  %s\n' "$sha" "$work/$archive" | sha256sum -c - > /dev/null
tar -xzf "$work/$archive" -C "$work" br
mkdir -p "$dest"
install -m 755 "$work/br" "$dest/br"
"$dest/br" --version
