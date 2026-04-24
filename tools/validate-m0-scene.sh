#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_path="${repo_root}/AstroAdventureM0"
output_dir="${repo_root}/artifacts/scene-validation"
log_file="${output_dir}/unity-validation.log"
unity_version="$(sed -n 's/^m_EditorVersion: //p' "${project_path}/ProjectSettings/ProjectVersion.txt" | head -n 1)"

if [[ -n "${UNITY_EXE:-}" ]]; then
  unity="${UNITY_EXE}"
else
  unity=""
  for version in "${unity_version}" "6000.4.4f1"; do
    for candidate in \
      "/mnt/c/Program Files/Unity/Hub/Editor/${version}/Editor/Unity.exe" \
      "/c/Program Files/Unity/Hub/Editor/${version}/Editor/Unity.exe" \
      "C:/Program Files/Unity/Hub/Editor/${version}/Editor/Unity.exe"; do
      if [[ -f "${candidate}" ]]; then
        unity="${candidate}"
        break 2
      fi
    done
  done
  unity="${unity:-C:/Program Files/Unity/Hub/Editor/${unity_version}/Editor/Unity.exe}"
fi

to_unity_path() {
  if command -v wslpath >/dev/null 2>&1; then
    wslpath -w "$1"
  elif command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

mkdir -p "${output_dir}"
rm -f "${output_dir}"/*.png "${output_dir}"/*.mp4 "${output_dir}/report.md" "${log_file}"

"${unity}" \
  -batchmode \
  -quit \
  -projectPath "$(to_unity_path "${project_path}")" \
  -executeMethod M0SceneValidator.Run \
  -logFile "$(to_unity_path "${log_file}")"

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
