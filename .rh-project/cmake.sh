#!/bin/bash

set -eu
set -o pipefail

SDPATH="$(dirname "${BASH_SOURCE[0]}")"
if [[ ! -d "${SDPATH}" ]]; then SDPATH="${PWD}"; fi
SDPATH="$(cd "${SDPATH}" && pwd)"
readonly SDPATH

PRJ_ROOT_PATH="${SDPATH}/.."
PRJ_ROOT_PATH="$(cd "${PRJ_ROOT_PATH}" && pwd)"
readonly PRJ_ROOT_PATH

source "${SDPATH}/conf.sh"

cd "${BLD_PATH}" && echo + cd "${PWD}"

echo
CMD=(source conanbuild.sh)
echo + "${CMD[@]}" && "${CMD[@]}"

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
