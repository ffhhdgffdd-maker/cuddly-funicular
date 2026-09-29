#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
c++ -std=c++11 -Wall -Wextra -Werror linux_tests/volume_reveal_test.cpp -o "$work/volume"
"$work/volume"
