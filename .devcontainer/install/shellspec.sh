#!/bin/sh
# shellcheck shell=sh
#
# Installs ShellSpec, the test runner for this project's shell, into ~/.local
# at a pinned version. Idempotent: does nothing when the pinned version is
# already installed.
set -eu
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

SHELLSPEC_VERSION=0.28.1

bin="$HOME/.local/bin/shellspec"
if [ -x "$bin" ] && [ "$("$bin" --version 2> /dev/null)" = "$SHELLSPEC_VERSION" ]; then
    exit 0
fi

# The `.tar.gz` suffix tells the installer to fetch the release archive rather
# than git-clone the repo.
run_installer https://raw.githubusercontent.com/shellspec/shellspec/master/install.sh \
    --yes -p "$HOME/.local" "$SHELLSPEC_VERSION.tar.gz"
