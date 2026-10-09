#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${project_dir}/build-release"
dist_dir="${project_dir}/dist"

cmake -S "${project_dir}" -B "${build_dir}" -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_SYSROOT="$(xcrun --sdk macosx --show-sdk-path)"
cmake --build "${build_dir}" --parallel
ctest --test-dir "${build_dir}" --output-on-failure

for bundle in "${build_dir}/RegionBounce.saver" "${build_dir}/RegionBounce Preview.app"; do
  codesign --force --deep --sign - "${bundle}"
  codesign --verify --deep --strict --verbose=2 "${bundle}"
done

mkdir -p "${dist_dir}"
staging_dir="$(mktemp -d)"
trap 'rm -rf "${staging_dir}"' EXIT
for package in RegionBounce-macOS RegionBounce-ScreenSaver RegionBounce-Preview; do
  package_dir="${staging_dir}/${package}"
  mkdir -p "${package_dir}"
  if [[ "${package}" != RegionBounce-Preview ]]; then
    ditto "${build_dir}/RegionBounce.saver" "${package_dir}/RegionBounce.saver"
  fi
  if [[ "${package}" != RegionBounce-ScreenSaver ]]; then
    ditto "${build_dir}/RegionBounce Preview.app" "${package_dir}/RegionBounce Preview.app"
  fi
  cp "${project_dir}/docs/INSTALL.txt" "${package_dir}/INSTALL.txt"
  cp "${project_dir}/LICENSE" "${package_dir}/LICENSE"
  archive="${dist_dir}/${package}.zip"
  rm -f "${archive}"
  ditto -c -k --sequesterRsrc --keepParent "${package_dir}" "${archive}"
  echo "Built ${archive}"
done
