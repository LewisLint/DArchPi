#!/usr/bin/env bash

set -Eeuo pipefail

exec "$(dirname -- "${BASH_SOURCE[0]}")/build-rpi-aarch64-image.sh" "$@"