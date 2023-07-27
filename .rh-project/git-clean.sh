#!/bin/bash

set -eu
set -o pipefail

SPATH="$(dirname "${BASH_SOURCE[0]}")"
if [[ ! -d "${SPATH}" ]]; then SPATH="${PWD}"; fi
readonly SPATH="$(cd "${SPATH}" && pwd)"

PRJ_ROOT_PATH="${SPATH}/.."
readonly PRJ_ROOT_PATH="$(cd "${PRJ_ROOT_PATH}" && pwd)"

cd "${PRJ_ROOT_PATH}" && echo + cd "${PWD}"

CMD=(git reset --hard)
echo + "${CMD[@]}" && "${CMD[@]}"

CMD=(git submodule foreach --recursive git reset --hard)
echo + "${CMD[@]}" && "${CMD[@]}"

CMD=(git clean -xfd)
echo + "${CMD[@]}" && "${CMD[@]}"

CMD=(git submodule foreach --recursive git clean -xfd)
echo + "${CMD[@]}" && "${CMD[@]}"
