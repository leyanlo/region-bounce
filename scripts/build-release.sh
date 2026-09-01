#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${project_dir}/build-release"
dist_dir="${project_dir}/dist"

cmake -S "${project_dir}" -B "${build_dir}" -DCMAKE_BUILD_TYPE=Release
cmake --build "${build_dir}" --parallel
ctest --test-dir "${build_dir}" --output-on-failure

for bundle in "${build_dir}/RegionBounce.saver" "${build_dir}/RegionBounce.app"; do
  codesign --force --deep --sign - "${bundle}"
  codesign --verify --deep --strict --verbose=2 "${bundle}"
done

mkdir -p "${dist_dir}"
staging_dir="$(mktemp -d)"
trap 'rm -rf "${staging_dir}"' EXIT
package_dir="${staging_dir}/RegionBounce-macOS"
mkdir -p "${package_dir}"
ditto "${build_dir}/RegionBounce.saver" "${package_dir}/RegionBounce.saver"
ditto "${build_dir}/RegionBounce.app" "${package_dir}/RegionBounce.app"
archive="${dist_dir}/RegionBounce-macOS.zip"
rm -f "${archive}"
ditto -c -k --sequesterRsrc --keepParent "${package_dir}" "${archive}"

echo "Built ${archive}"
