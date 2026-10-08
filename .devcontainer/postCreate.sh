#!/bin/sh
# shellcheck shell=sh
#
# Installs every tool the project needs. Runs inside the container only; the
# host gets nothing installed.
set -eu

# Pinned for reproducible rebuilds. Tools fetched with curl are pinned in
# their own scripts under .devcontainer/install/.
OPENCODE_VERSION=1.18.35

# ---- volume ownership ----
#
# Docker creates every named volume root-owned, and also creates any missing
# parent of a mount target (~/.local, ~/.local/share, ~/.config) root-owned.
# Without this, each host's login fails with EACCES, and so does any install
# into ~/.local/bin.
sudo chown "$USER:$USER" "$HOME/.local" "$HOME/.local/share" "$HOME/.config"
sudo chown -R "$USER:$USER" \
    "$HOME/.codex" "$HOME/.local/share/opencode" "$HOME/.gemini" "$HOME/.config/muse"
# statusline-command.sh is a read-only bind mount nested inside the ~/.claude
# volume; chown fails on it, so prune it.
sudo find "$HOME/.claude" -path "$HOME/.claude/statusline-command.sh" -prune \
    -o -exec chown "$USER:$USER" {} +
mkdir -p "$HOME/.local/bin"

# ---- Claude Code ----
#
# The claude-code feature installs into nvm's global node_modules as root,
# without group write, while every other nvm global is group `nvm`, setgid and
# group-writable. `claude update` is a global npm install and hits EACCES on
# that one tree. Restore group write on just that subtree.
sudo chmod -R g+w "$(npm root -g)/@anthropic-ai"

# Point Claude Code at the bind-mounted statusline script. Guarded on `-f`
# because docker materialises a directory when the host has no such file.
# Merged, not overwritten: ~/.claude is a persisted volume, so a rebuild finds
# settings.json already populated. jq comes from the base image.
if [ -f "$HOME/.claude/statusline-command.sh" ]; then
    settings="$HOME/.claude/settings.json"
    [ -f "$settings" ] || printf '{}\n' > "$settings"
    tmp=$(mktemp "$settings.XXXXXX")
    jq '.statusLine = {type: "command", command: "~/.claude/statusline-command.sh"}' \
        "$settings" > "$tmp"
    chmod 644 "$tmp"
    mv "$tmp" "$settings"
fi

# ---- shell toolchain ----
#
#   - shellcheck          lint; `# shellcheck shell=sh` makes it flag bashisms
#   - shfmt               formatter; reads .editorconfig
#   - dash, ksh, busybox  other shells to run the same specs under, which is
#                         what proves portability
sudo apt-get update
sudo apt-get install -y --no-install-recommends shellcheck shfmt dash ksh busybox
sudo rm -rf /var/lib/apt/lists/*

# busybox dispatches on argv[0]; this symlink makes its ash applet a
# single-word command, which `shellspec --shell` needs.
sudo ln -sf "$(command -v busybox)" /usr/local/bin/ash

# ---- tools fetched with curl ----
#
# One script per tool, so that each can also be run by hand in a running
# container without a rebuild. Each does nothing when its tool is already
# installed. br, ShellSpec and codex fail the container if they cannot
# install; agy and muse only warn, so one missing host does not fail the whole
# container.
#
#   - shellspec    test runner written in POSIX sh, so one specfile runs under
#                  every shell above
#   - beads_rust   br, the project's tracker
#   - codex        the Codex CLI, newer than the one npm ci installs below
#   - antigravity  agy, the Antigravity CLI
#   - muse         Muse Code
for tool in shellspec beads_rust codex antigravity muse; do
    sh ".devcontainer/install/$tool.sh"
done

# ---- project dependencies ----
#
# promptfoo, prettier and the SDKs are pinned in package.json. An older Codex
# CLI arrives here too: promptfoo -> @openai/codex-sdk -> @openai/codex puts it
# in node_modules/.bin, behind install/codex.sh's on PATH. The openai:codex-sdk
# provider ignores PATH and drives this one unless told otherwise.
# package-lock.json is committed, so `npm ci` installs exactly what it pins.
npm ci

# ---- OpenCode ----
npm install -g "opencode-ai@$OPENCODE_VERSION"

# ---- PATH ----
#
# devcontainer.json sets PATH with remoteEnv, so that every process the
# container starts finds ~/.local/bin and node_modules/.bin, not only an
# interactive bash. Nothing is written to ~/.bashrc.
