.POSIX:
SHELL = /bin/sh

# `make check` is the quality gate: what every prompt, task and CI run treats
# as done. It is model-free: no target calls a model or needs a login.

# Shells the shell specs must pass under. `sh` is dash on Debian, but is listed
# on its own because it is what a script gets at runtime. `ash` is busybox's.
SHELLS = sh dash ash bash ksh

# Shell sources to lint. Specfiles are a DSL that shellcheck reads as undefined
# commands, so they are left out; .editorconfig keeps shfmt off them too.
FIND_SH = find . -path ./node_modules -prune -o -path ./.git -prune -o -type f -name '*.sh' ! -name '*_spec.sh' -print

# make runs under a non-interactive /bin/sh, which need not have
# node_modules/.bin on PATH.
BIN = ./node_modules/.bin

# eslint.config.ts is loaded by Node's own type stripping, not by the jiti
# package ESLint asks for. The flag is still marked unstable in ESLint 10.11;
# re-check it when moving ESLint.
ESLINT = $(BIN)/eslint --flag unstable_native_nodejs_ts_config

help:
	@echo 'targets:'
	@echo '  check        the quality gate: every target below except fmt'
	@echo '  lint         shellcheck every shell source; eslint every TypeScript source'
	@echo '  typecheck    tsc --noEmit'
	@echo '  fmt-check    shfmt -d and prettier --check; non-zero if anything is unformatted'
	@echo '  fmt          shfmt -w and prettier --write'
	@echo '  test-ts      node --test every *.test.ts outside node_modules'
	@echo '  test-sh      shellspec under each of: $(SHELLS)'
	@echo '  check-beads  approved specs and task beads agree (PROMPTS.md -> Tracking)'

check: lint typecheck fmt-check test-ts test-sh check-beads

lint:
	@files=`$(FIND_SH)`; \
	[ -z "$$files" ] || shellcheck -x $$files
	$(ESLINT) --max-warnings 0 .

typecheck:
	$(BIN)/tsc --noEmit

fmt-check:
	shfmt -d .
	$(BIN)/prettier --check --log-level warn .

fmt:
	shfmt -w .
	$(BIN)/prettier --write --log-level warn .

test-ts:
	node --test '**/*.test.ts'

# The portability proof: the same specfiles run by each shell. A shell that is
# missing fails the gate rather than being skipped.
test-sh:
	@for s in $(SHELLS); do \
		echo "==> shellspec --shell $$s"; \
		shellspec --shell "$$s" || exit 1; \
	done

check-beads:
	node scripts/check-beads.ts

.PHONY: help check lint typecheck fmt-check fmt test-ts test-sh check-beads
