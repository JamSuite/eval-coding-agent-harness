#!/bin/sh
# shellcheck shell=sh
#
# Installs Muse Code (`muse`) into ~/.local/bin. Meta's product page lists
# macOS and Windows only, but the installer works on Linux. It always fetches
# the latest launcher and muse updates itself, so there is no version to pin: a
# muse that runs counts as installed. Warns rather than fails, so a broken
# installer cannot fail the container.
set -eu
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

muse="$HOME/.local/bin/muse"
if [ -x "$muse" ] && "$muse" --version > /dev/null 2>&1; then
    exit 0
fi

if ! run_installer https://dev.meta.ai/install.sh \
    || ! "$muse" --version > /dev/null 2>&1; then
    warn 'Muse Code (muse) did not install; record this in README.md'
fi
