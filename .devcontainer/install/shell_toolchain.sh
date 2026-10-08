#!/bin/sh
# shellcheck shell=sh
#
# Installs the shell toolchain from apt. Idempotent: does nothing when every
# tool is already on PATH.
#
#   - shellcheck          lint; `# shellcheck shell=sh` makes it flag bashisms
#   - shfmt               formatter; reads .editorconfig
#   - dash, ksh, busybox  other shells to run the same specs under, which is
#                         what proves portability
set -eu

missing=
for tool in shellcheck shfmt dash ksh busybox ash; do
    command -v "$tool" > /dev/null 2>&1 || missing=1
done
[ -n "$missing" ] || exit 0

sudo apt-get update
sudo apt-get install -y --no-install-recommends shellcheck shfmt dash ksh busybox
sudo rm -rf /var/lib/apt/lists/*

# busybox dispatches on argv[0]; this symlink makes its ash applet a
# single-word command, which `shellspec --shell` needs.
sudo ln -sf "$(command -v busybox)" /usr/local/bin/ash
