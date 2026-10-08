# shellcheck shell=sh
#
# Sourced by the install scripts beside it; not run on its own.

# Prints a warning and carries on. Used only for hosts that may have no Linux
# build, so that one missing host does not fail the whole container.
warn() {
    printf '%s: WARNING: %s\n' "${0##*/}" "$*" >&2
}

# Downloads installer $1 to a file and runs it with bash, passing the remaining
# arguments. `curl | bash` would hide a failed download, because POSIX sh has
# no pipefail.
#
# antigravity.google's caches sometimes serve the script gzipped without
# Content-Encoding, so curl cannot know to decode it and saves the compressed
# bytes. A body that starts with the gzip magic number is decompressed first.
run_installer() {
    run_installer_dir=$(mktemp -d)
    run_installer_file="$run_installer_dir/install.sh"
    run_installer_url=$1
    shift
    run_installer_status=0
    if curl -fsSL "$run_installer_url" -o "$run_installer_file"; then
        if [ "$(od -An -tx1 -N2 "$run_installer_file" | tr -d ' \n')" = 1f8b ]; then
            gzip -dc < "$run_installer_file" > "$run_installer_file.txt"
            mv "$run_installer_file.txt" "$run_installer_file"
        fi
        bash "$run_installer_file" "$@" || run_installer_status=$?
    else
        run_installer_status=1
    fi
    rm -rf "$run_installer_dir"
    return "$run_installer_status"
}
