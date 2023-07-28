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
CMD=(source conanbuild.sh)
echo + "${CMD[@]}" && "${CMD[@]}"

cmake --version

CMD=(cmake)
CMD+=(..)
CMD+=("-DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake")
CMD+=("-DCMAKE_EXPORT_COMPILE_COMMANDS=True")
# CMD+=("-DCMAKE_C_COMPILER=${CC}")
# CMD+=("-DCMAKE_CXX_COMPILER=${CXX}")
CMD+=("-DCMAKE_BUILD_TYPE=Release")
echo + "${CMD[@]}" && "${CMD[@]}"

echo
CMD=(source deactivate_conanbuild.sh)
echo + "${CMD[@]}" && "${CMD[@]}"
