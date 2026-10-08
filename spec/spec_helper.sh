# shellcheck shell=sh
#
# Loaded before every specfile. Keep it POSIX: these specs must also run under
# dash, ksh and busybox ash.

# Invoked once, before any specfile is loaded.
spec_helper_precheck() {
    minimum_version "0.28.1"
}
