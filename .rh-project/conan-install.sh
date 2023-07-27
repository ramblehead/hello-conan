#!/bin/bash

set -eu
set -o pipefail

SPATH="$(dirname "${BASH_SOURCE[0]}")"
if [[ ! -d "${SPATH}" ]]; then SPATH="${PWD}"; fi
readonly SPATH="$(cd "${SPATH}" && pwd)"

PRJ_ROOT_PATH="${SPATH}/.."
readonly PRJ_ROOT_PATH="$(cd "${PRJ_ROOT_PATH}" && pwd)"

cd "${PRJ_ROOT_PATH}" && echo + cd "${PWD}"

CMD=(poetry run conan install)
CMD+=(.)
CMD+=("--output-folder=build")
# CMD+=('--build="*"')
CMD+=("--build=missing")
CMD+=("-pr:h=./utils/conan2/profiles/clang-15")
CMD+=("-pr:b=./utils/conan2/profiles/clang-15")
echo + "${CMD[@]}" && eval "${CMD[@]}"
