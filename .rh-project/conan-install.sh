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

cd "${PRJ_ROOT_PATH}" && echo + cd "${PWD}"

CMD=(poetry run conan install)
CMD+=(.)
CMD+=("--output-folder=build")
# CMD+=('--build="*"')
CMD+=("--build=missing")
CMD+=("-pr:h=./utils/conan2/profiles/clang-16")
CMD+=("-pr:b=./utils/conan2/profiles/clang-16")
# shellcheck disable=2294
echo + "${CMD[@]}" && eval "${CMD[@]}"
