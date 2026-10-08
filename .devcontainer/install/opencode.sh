#!/bin/sh
# shellcheck shell=sh
#
# Installs OpenCode (`opencode`) at a pinned version as a global npm package.
# Idempotent: does nothing when the pinned version is already installed.
#
# OpenCode is a deferred host. It stays installed so that it can come back
# without a rebuild.
set -eu

OPENCODE_VERSION=1.18.35

if command -v opencode > /dev/null 2>&1 \
    && [ "$(opencode --version 2> /dev/null)" = "$OPENCODE_VERSION" ]; then
    exit 0
fi

npm install -g "opencode-ai@$OPENCODE_VERSION"
