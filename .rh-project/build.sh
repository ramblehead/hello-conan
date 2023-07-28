#!/bin/bash

set -eu
set -o pipefail

SPATH="$(dirname "${BASH_SOURCE[0]}")"
if [[ ! -d "${SPATH}" ]]; then SPATH="${PWD}"; fi
readonly SPATH="$(cd "${SPATH}" && pwd)"

PRJ_ROOT_PATH="${SPATH}/.."
readonly PRJ_ROOT_PATH="$(cd "${PRJ_ROOT_PATH}" && pwd)"

BUILD_PATH="${PRJ_ROOT_PATH}/build"

cd "${BUILD_PATH}" && echo + cd "${PWD}"

echo
source conanbuild.sh

CMD=(cmake)
CMD+=(--build)
CMD+=(.)
CMD+=("--config=Release")
echo + "${CMD[@]}" && "${CMD[@]}"

echo
source deactivate_conanbuild.sh
