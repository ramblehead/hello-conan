#!/bin/bash

set -eu
set -o pipefail

SDPATH="$(dirname "${BASH_SOURCE[0]}")"
if [[ ! -d "${SDPATH}" ]]; then SDPATH="${PWD}"; fi
SDPATH="$(cd -P "${SDPATH}" && pwd)"
readonly SDPATH

PRJ_ROOT_PATH="${SDPATH}/.."
PRJ_ROOT_PATH="$(cd "${PRJ_ROOT_PATH}" && pwd)"
readonly PRJ_ROOT_PATH

source "${SDPATH}/conf.sh"

cd "${PRJ_ROOT_PATH}" && echo + cd "${PWD}"

# Set the directory to search
SRC="${PRJ_ROOT_PATH}/src"

cleanup() {
  rm -f "${temp_count_file}"
}

temp_count_file=$(mktemp)
export temp_count_file

trap cleanup EXIT

error_total_count=0
warning_total_count=0

SRC_TYPES=(-name '*.cpp' -o -name '*.hpp' -o -name '*.c' -o -name '*.h')

find "${SRC}" -type f \( "${SRC_TYPES[@]}" \) -print0 |
while IFS= read -r -d '' FILE; do
  output=$(clang-tidy-${CLANG_VERSION} "${FILE}" | tee /dev/tty) ||:
  warning_count=$(echo "${output}" | grep -ci "warning\:") ||:
  error_count=$(echo "${output}" | grep -ci "error\:") ||:

  echo
  echo "For ${FILE}:"
  echo "  File total number of clang-tidy errors: ${error_count}"
  echo "  File total number of clang-tidy warnings: ${warning_count}"

  echo "((error_total_count += ${error_count})) ||:" >> "${temp_count_file}"
  echo "((warning_total_count += ${warning_count})) ||:" >> "${temp_count_file}"
done

# shellcheck disable=1090
source "${temp_count_file}"

echo
echo "Project total number of clang-tidy errors: ${error_total_count}"
echo "Project total number of clang-tidy warnings: ${warning_total_count}"
