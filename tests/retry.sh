#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/common.sh
sleep() { :; }
attempts=0
fail() { attempts=$((attempts+1)); return 42; }
if installfromnet fail; then echo 'failed command reported success' >&2; exit 1; else status=$?; fi
[[ $status == 42 && $attempts == 5 ]]
attempts=0
eventually() { attempts=$((attempts+1)); [[ $attempts == 3 ]]; }
installfromnet eventually
[[ $attempts == 3 ]]
check_args() { [[ $# == 2 && $1 == 'with spaces' && $2 == '*.literal' ]]; }
installfromnet check_args 'with spaces' '*.literal'
echo 'retry regression tests: ok'
