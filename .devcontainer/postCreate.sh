#!/bin/sh
# shellcheck shell=sh
#
# Installs every tool the project needs. Runs inside the container only; the
# host gets nothing installed.
set -eu

# Pinned for reproducible rebuilds. The `.tar.gz` suffix tells the ShellSpec
# installer to fetch the release archive rather than git-clone the repo.
SHELLSPEC_VERSION=0.28.1.tar.gz
OPENCODE_VERSION=1.18.35

# Prints a warning and carries on. Used only for hosts that may have no Linux
# build, so that one missing host does not fail the whole container.
warn() {
    printf 'postCreate.sh: WARNING: %s\n' "$*" >&2
}

# Downloads an installer to a file before running it. `curl | bash` would hide
# a failed download, because POSIX sh has no pipefail.
run_installer() {
    run_installer_file=$(mktemp)
    curl -fsSL "$1" -o "$run_installer_file" || {
        rm -f "$run_installer_file"
        return 1
    }
    bash "$run_installer_file"
    run_installer_status=$?
    rm -f "$run_installer_file"
    return "$run_installer_status"
}

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

# ShellSpec: test runner written in POSIX sh, so one specfile runs under every
# shell above.
shellspec_installer=$(mktemp)
curl -fsSL https://raw.githubusercontent.com/shellspec/shellspec/master/install.sh \
    -o "$shellspec_installer"
sh "$shellspec_installer" --yes -p "$HOME/.local" "$SHELLSPEC_VERSION"
rm -f "$shellspec_installer"

# ---- beads_rust (br) ----
#
# The project's tracker. Pinned and checksum-checked in its own script so that
# it can also be installed into a running container without a rebuild.
sh .devcontainer/install-br.sh

# ---- project dependencies ----
#
# promptfoo, prettier and the SDKs are pinned in package.json. The Codex CLI
# arrives here too: promptfoo -> @openai/codex-sdk -> @openai/codex puts
# `codex` in node_modules/.bin, the binary the openai:codex-sdk provider drives.
# package-lock.json is committed, so `npm ci` installs exactly what it pins.
npm ci

# ---- OpenCode ----
npm install -g "opencode-ai@$OPENCODE_VERSION"

# ---- Antigravity CLI ----
# The installer writes ~/.local/bin/agy and verifies its checksum.
run_installer https://antigravity.google/cli/install.sh \
    || warn 'Antigravity CLI (agy) did not install; record this in README.md'

# ---- Muse Code ----
# Meta's product page lists macOS and Windows only, but the installer works on
# Linux. It still warns rather than fails, so a broken installer cannot fail
# the container.
run_installer https://dev.meta.ai/install.sh \
    || warn 'Muse Code (muse) did not install; record this in README.md'

# ---- PATH ----
#
# Unquoted heredoc: $PWD is expanded now (postCreateCommand runs in the
# workspace folder), while \$HOME and \$PATH stay literal and are evaluated per
# shell. node_modules/.bin carries codex, promptfoo and prettier.
if ! grep -q '### BEGIN devcontainer postCreate.sh' "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" << EOT

### BEGIN devcontainer postCreate.sh
export PATH="\$HOME/.local/bin:$PWD/node_modules/.bin:\$PATH"
### END devcontainer postCreate.sh
EOT
fi
