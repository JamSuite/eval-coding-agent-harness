#!/bin/sh
# shellcheck shell=sh
#
# Installs the Antigravity CLI (`agy`) into ~/.local/bin. The installer always
# fetches the latest build and agy updates itself, so there is no version to
# pin: an agy that runs counts as installed. Warns rather than fails, so a
# broken installer cannot fail the container.
set -eu
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

agy="$HOME/.local/bin/agy"
if [ -x "$agy" ] && "$agy" --version > /dev/null 2>&1; then
    exit 0
fi

# The installer checks the binary's SHA-512 against its release manifest.
if ! run_installer https://antigravity.google/cli/install.sh \
    || ! "$agy" --version > /dev/null 2>&1; then
    warn 'Antigravity CLI (agy) did not install; record this in README.md'
fi
