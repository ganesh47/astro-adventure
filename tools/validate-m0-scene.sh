#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
unity="${UNITY_EXE:-/mnt/c/Program Files/Unity/Hub/Editor/6000.4.4f1/Editor/Unity.exe}"
project_path="${repo_root}/AstroAdventureM0"
output_dir="${repo_root}/artifacts/scene-validation"
log_file="${output_dir}/unity-validation.log"

mkdir -p "${output_dir}"
rm -f "${output_dir}"/*.png "${output_dir}"/*.mp4 "${output_dir}/report.md" "${log_file}"

"${unity}" \
  -batchmode \
  -quit \
  -projectPath "$(wslpath -w "${project_path}")" \
  -executeMethod M0SceneValidator.Run \
  -logFile "$(wslpath -w "${log_file}")"

if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -y \
    -framerate 1 \
    -pattern_type glob \
    -i "${output_dir}/*.png" \
    -vf "scale=1280:-2,format=yuv420p" \
    "${output_dir}/m0-scene-validation.mp4" \
    >/dev/null 2>&1 || true
fi

echo "Validation artifacts:"
echo "${output_dir}"
