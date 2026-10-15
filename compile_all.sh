#!/usr/bin/env bash
# Run from a machine with arduino-cli and the dependencies listed in README_VI.md.
set -euo pipefail
cd "$(dirname "$0")"
CLI="${ARDUINO_CLI:-arduino-cli}"
# Optional config: ARDUINO_CLI_CONFIG=/path/to/arduino-cli.yaml bash compile_all.sh
ARGS=()
if [[ -n "${ARDUINO_CLI_CONFIG:-}" ]]; then ARGS+=(--config-file "$ARDUINO_CLI_CONFIG"); fi
python3 tools/embed_web.py
cmp SmartController_C3/Protocol.h USB_Bridge_S3/Protocol.h
cmp SmartController_C3/Protocol.h Receiver_Test/Protocol.h
cmp Receiver_Test/ReceiverLink.h USB_Bridge_S3/ReceiverLink.h
"$CLI" "${ARGS[@]}" compile --jobs 3 --fqbn 'esp32:esp32:esp32c3:CDCOnBoot=cdc,PartitionScheme=huge_app' SmartController_C3
"$CLI" "${ARGS[@]}" compile --jobs 3 --fqbn 'esp32:esp32:esp32s3:USBMode=default,CDCOnBoot=cdc,PartitionScheme=huge_app' USB_Bridge_S3
"$CLI" "${ARGS[@]}" compile --jobs 3 --fqbn 'esp32:esp32:esp32:PartitionScheme=huge_app' Receiver_Test
"$CLI" "${ARGS[@]}" compile --jobs 3 --fqbn 'esp32:esp32:esp32c3:CDCOnBoot=cdc,PartitionScheme=huge_app' Receiver_Test
