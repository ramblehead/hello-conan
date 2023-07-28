#!/bin/bash

set -eu
set -o pipefail

SPATH="$(dirname "${BASH_SOURCE[0]}")"
if [[ ! -d "${SPATH}" ]]; then SPATH="${PWD}"; fi
SPATH="$(cd "${SPATH}" && pwd)"
readonly SPATH

PRJ_ROOT_PATH="${SPATH}/.."
PRJ_ROOT_PATH="$(cd "${PRJ_ROOT_PATH}" && pwd)"
readonly PRJ_ROOT_PATH

BUILD_PATH="${PRJ_ROOT_PATH}/build"

cd "${BUILD_PATH}" && echo + cd "${PWD}"

echo
CMD=(source conanrun.sh)
echo + "${CMD[@]}" && "${CMD[@]}"

echo
CMD=(./compressor)
echo + "${CMD[@]}" && "${CMD[@]}"

echo
CMD=(source deactivate_conanrun.sh)
echo + "${CMD[@]}" && "${CMD[@]}"
