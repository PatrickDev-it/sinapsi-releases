#!/usr/bin/env bash
# Runs one build command with its full output kept on the runner, never in the log.
#
# This repository is public and so are its Actions logs, while the source it builds is
# proprietary. A compiler diagnostic quotes the offending source lines, so a failed build
# printed in full would publish them. On failure only the headline of each diagnostic is shown
# (`file:line:col: error[...]: message`, `error TS...`, panics, the Tauri CLI's `Error ...`
# lines); on success only the count of warnings. The full log is deleted with the runner.
#
# Usage: bash ci/quiet.sh <command> [args...]
set -uo pipefail

log="$(mktemp)"
"$@" >"$log" 2>&1
status=$?

if [ "$status" -ne 0 ]; then
    echo "::error title=$1 failed::exit status $status; diagnostic headlines only (the full log never leaves the runner)"
    grep -E '(^|: )(error|fatal)(\[[A-Z0-9]+\])?:|error TS[0-9]+|^error:|^[[:space:]]*Error[[:space:]:]|panicked at|npm ERR!' "$log" | head -n 80 || true
else
    warnings="$(grep -cE '(^|: )warning(\[[A-Za-z0-9_-]+\])?:' "$log" || true)"
    echo "ok: $1 (${warnings:-0} warning lines withheld)"
fi
rm -f "$log"
exit "$status"
