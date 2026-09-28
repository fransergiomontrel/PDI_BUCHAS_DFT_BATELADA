#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_build=$(mktemp -d)
trap 'rm -rf "$test_build"' EXIT
iverilog -g2012 -s uart_tx_timing_tb -o "$test_build/uart_tb" \
    tests/uart_tx_timing_tb.v tests/reference/uart_tx_reference.v uart_tx.v uart_tx_8.v
vvp "$test_build/uart_tb"
