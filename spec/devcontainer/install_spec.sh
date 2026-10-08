# shellcheck shell=sh
#
# Offline: curl and every tool binary are stubs, found first on PATH or in a
# throwaway $HOME. Nothing here touches the network.

INSTALL=.devcontainer/install

setup() {
    TEST_HOME=$(mktemp -d)
    STUBS="$TEST_HOME/stubs"
    mkdir -p "$STUBS" "$TEST_HOME/.local/bin"
    CURL_LOG="$TEST_HOME/curl.log"
    CURL_BODY="$TEST_HOME/body"
    CURL_EXIT=0
    : > "$CURL_LOG"
    : > "$CURL_BODY"
    # Writes the file named by -o, or stdout, from $CURL_BODY; or fails with
    # $CURL_EXIT. Logs each call so a test can assert that none was made.
    cat > "$STUBS/curl" << 'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$CURL_LOG"
if [ "$CURL_EXIT" -ne 0 ]; then
    echo "curl: ($CURL_EXIT) The requested URL returned error" >&2
    exit "$CURL_EXIT"
fi
out=
while [ $# -gt 0 ]; do
    case $1 in
        -o | --output) out=$2 && shift ;;
    esac
    shift
done
if [ -n "$out" ]; then cat "$CURL_BODY" > "$out"; else cat "$CURL_BODY"; fi
STUB
    chmod +x "$STUBS/curl"
    export HOME="$TEST_HOME" PATH="$STUBS:$PATH" CURL_LOG CURL_BODY CURL_EXIT
}

cleanup() {
    rm -rf "$TEST_HOME"
}

BeforeEach setup
AfterEach cleanup

# Puts an executable at ~/.local/bin/$1 that prints $2 for any arguments.
stub_tool() {
    printf '#!/bin/sh\necho "%s"\n' "$2" > "$HOME/.local/bin/$1"
    chmod +x "$HOME/.local/bin/$1"
}

curl_calls() {
    wc -l < "$CURL_LOG" | tr -d ' '
}

Describe 'lib.sh run_installer'
    Include .devcontainer/install/lib.sh

    It 'runs a plain installer and passes it the remaining arguments'
        printf 'echo "ran with $*"\n' > "$CURL_BODY"
        When call run_installer https://example.test/install.sh --yes
        The output should equal 'ran with --yes'
        The status should be success
    End

    # antigravity.google's caches sometimes serve the script gzipped without
    # Content-Encoding, so curl saves the compressed bytes.
    It 'decompresses an installer served gzipped without Content-Encoding'
        printf 'echo ran\n' | gzip -c > "$CURL_BODY"
        When call run_installer https://example.test/install.sh
        The output should equal 'ran'
        The status should be success
    End

    It 'fails when the download fails'
        CURL_EXIT=22
        When call run_installer https://example.test/install.sh
        The status should be failure
        The stderr should be present
    End

    It 'returns the status of a failing installer'
        printf 'exit 3\n' > "$CURL_BODY"
        When call run_installer https://example.test/install.sh
        The status should equal 3
    End
End

Describe 'install scripts skip a tool that is already present'
    Parameters
        beads_rust.sh br 'br 0.7.4'
        shellspec.sh shellspec '0.28.1'
        antigravity.sh agy 'agy 1.0.0'
        muse.sh muse 'Muse Code 1.4.4'
    End

    It "$1 makes no download when $2 is present"
        stub_tool "$2" "$3"
        When run sh "$INSTALL/$1"
        The status should be success
        The result of function curl_calls should equal 0
    End
End

Describe 'install scripts replace a pinned tool at another version'
    Parameters
        beads_rust.sh br 'br 0.7.3'
        shellspec.sh shellspec '0.28.0'
        codex.sh codex 'codex-cli 0.156.1'
    End

    It "$1 downloads when $2 reports $3"
        stub_tool "$2" "$3"
        CURL_EXIT=22
        When run sh "$INSTALL/$1"
        The status should be failure
        The stderr should be present
        The result of function curl_calls should not equal 0
    End
End

Describe 'a failed download'
    Describe 'fails the install of a required tool'
        Parameters
            beads_rust.sh
            shellspec.sh
            codex.sh
        End

        It "$1 exits non-zero"
            CURL_EXIT=22
            When run sh "$INSTALL/$1"
            The status should be failure
            The stderr should be present
        End
    End

    Describe 'warns for an optional host'
        Parameters
            antigravity.sh agy
            muse.sh muse
        End

        It "$1 warns and exits zero"
            CURL_EXIT=22
            When run sh "$INSTALL/$1"
            The status should be success
            The stderr should include "WARNING"
            The stderr should include "($2)"
        End

        It "$1 warns when the installer succeeds but leaves no $2"
            printf 'exit 0\n' > "$CURL_BODY"
            When run sh "$INSTALL/$1"
            The status should be success
            The stderr should include "WARNING"
        End
    End
End

codex_target() {
    case $(uname -m) in
        aarch64 | arm64) echo aarch64-unknown-linux-musl ;;
        *) echo x86_64-unknown-linux-musl ;;
    esac
}

# Lays out a package release reporting $1, as codex.sh would unpack it, with
# ~/.local/bin/codex linked to its entrypoint.
stub_codex_package() {
    release="$HOME/.local/share/codex/$1-$(codex_target)"
    mkdir -p "$release/bin"
    printf '{"version": "%s"}\n' "$1" > "$release/codex-package.json"
    printf '#!/bin/sh\necho "codex-cli %s"\n' "$1" > "$release/bin/codex"
    chmod +x "$release/bin/codex"
    ln -sf "$release/bin/codex" "$HOME/.local/bin/codex"
}

Describe 'codex.sh installs the full package'
    It 'makes no download when the pinned package is linked'
        stub_codex_package 0.162.0
        When run sh "$INSTALL/codex.sh"
        The status should be success
        The result of function curl_calls should equal 0
    End

    It 'downloads when the package is linked at another version'
        stub_codex_package 0.156.1
        CURL_EXIT=22
        When run sh "$INSTALL/codex.sh"
        The status should be failure
        The stderr should be present
        The result of function curl_calls should not equal 0
    End

    # The bare binary reports the pinned version, but the interactive TUI
    # refuses to start without the package around it.
    It 'downloads the package over a bare binary at the pinned version'
        stub_tool codex 'codex-cli 0.162.0'
        CURL_EXIT=22
        When run sh "$INSTALL/codex.sh"
        The status should be failure
        The stderr should be present
        The result of function curl_calls should not equal 0
    End

    It 'downloads the package archive'
        CURL_EXIT=22
        When run sh "$INSTALL/codex.sh"
        The status should be failure
        The stderr should be present
        The contents of file "$CURL_LOG" should include "codex-package-$(codex_target).tar.gz"
    End
End

Describe 'codex.sh checks the pinned checksum'
    # A well-formed package holding a fake binary, so that only the checksum
    # stands between it and ~/.local/bin.
    tampered_archive() {
        mkdir -p "$TEST_HOME/pkg/bin"
        printf '#!/bin/sh\necho "codex-cli 0.162.0"\n' > "$TEST_HOME/pkg/bin/codex"
        chmod +x "$TEST_HOME/pkg/bin/codex"
        echo '{}' > "$TEST_HOME/pkg/codex-package.json"
        tar -czf "$CURL_BODY" -C "$TEST_HOME/pkg" .
    }

    It 'fails and installs nothing when the archive does not match'
        tampered_archive
        When run sh "$INSTALL/codex.sh"
        The status should be failure
        The stderr should be present
        The path "$HOME/.local/bin/codex" should not be exist
        The path "$HOME/.local/share/codex" should not be exist
    End
End

# Puts a stub for $1 first on PATH that logs each call to $CMD_LOG and exits
# with $2 (default 0).
stub_command() {
    cat > "$STUBS/$1" << STUB
#!/bin/sh
printf '%s\\n' "$1 \$*" >> "\$CMD_LOG"
exit ${2:-0}
STUB
    chmod +x "$STUBS/$1"
}

command_calls() {
    wc -l < "$CMD_LOG" | tr -d ' '
}

Describe 'opencode.sh'
    setup_opencode() {
        CMD_LOG="$TEST_HOME/cmd.log"
        : > "$CMD_LOG"
        export CMD_LOG
    }
    BeforeEach setup_opencode

    It 'makes no install when the pinned opencode is present'
        printf '#!/bin/sh\necho 1.18.35\n' > "$STUBS/opencode"
        chmod +x "$STUBS/opencode"
        stub_command npm
        When run sh "$INSTALL/opencode.sh"
        The status should be success
        The result of function command_calls should equal 0
    End

    It 'installs the pinned version when opencode reports another'
        printf '#!/bin/sh\necho 1.18.34\n' > "$STUBS/opencode"
        chmod +x "$STUBS/opencode"
        stub_command npm
        When run sh "$INSTALL/opencode.sh"
        The status should be success
        The contents of file "$CMD_LOG" should include "npm install -g opencode-ai@1.18.35"
    End

    It 'fails when npm fails'
        printf '#!/bin/sh\necho 1.18.34\n' > "$STUBS/opencode"
        chmod +x "$STUBS/opencode"
        stub_command npm 1
        When run sh "$INSTALL/opencode.sh"
        The status should be failure
    End
End

Describe 'shell_toolchain.sh'
    setup_toolchain() {
        CMD_LOG="$TEST_HOME/cmd.log"
        : > "$CMD_LOG"
        export CMD_LOG
        stub_command sudo
    }
    BeforeEach setup_toolchain

    It 'makes no install when every tool is present'
        for tool in shellcheck shfmt dash ksh busybox ash; do
            printf '#!/bin/sh\n' > "$STUBS/$tool"
            chmod +x "$STUBS/$tool"
        done
        When run sh "$INSTALL/shell_toolchain.sh"
        The status should be success
        The result of function command_calls should equal 0
    End

    # The container has the real tools; a PATH of stubs and a few basics hides
    # them.
    isolate_path() {
        mkdir -p "$TEST_HOME/bin"
        for cmd in sh cat wc tr rm chmod; do
            ln -s "$(command -v "$cmd")" "$TEST_HOME/bin/$cmd"
        done
        PATH="$STUBS:$TEST_HOME/bin"
    }

    It 'installs with apt when a tool is missing'
        isolate_path
        When run sh "$INSTALL/shell_toolchain.sh"
        The status should be success
        The contents of file "$CMD_LOG" should include "apt-get install"
        The contents of file "$CMD_LOG" should include "busybox"
        The contents of file "$CMD_LOG" should include "/usr/local/bin/ash"
    End

    It 'fails when apt fails'
        isolate_path
        stub_command sudo 100
        When run sh "$INSTALL/shell_toolchain.sh"
        The status should be failure
    End
End
