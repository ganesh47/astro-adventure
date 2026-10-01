#!/bin/sh
# Xcode Cloud post-clone hook.
#
# Xcode Cloud calls this script after cloning the repository. It regenerates
# the committed Xcode project and stamps a unique App Store build number.

set -eu

REPOSITORY_PATH="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"

echo "--- Installing XcodeGen when needed ---"
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi

cd "$REPOSITORY_PATH"

# Fetch the tracked movie and image binaries before validation and archiving.
if ! command -v git-lfs >/dev/null 2>&1; then
  brew install git-lfs
fi
git lfs install --local
git lfs pull

python3 scripts/validate_repository.py

if [ -n "${CI_BUILD_NUMBER:-}" ]; then
  echo "--- Setting CURRENT_PROJECT_VERSION=${CI_BUILD_NUMBER} ---"
  sed -i '' \
    "s/CURRENT_PROJECT_VERSION: .*/CURRENT_PROJECT_VERSION: ${CI_BUILD_NUMBER}/" \
    project.yml
fi

if [ -n "${CI_TAG:-}" ]; then
  RELEASE_VERSION="${CI_TAG#v}"
  echo "--- Setting MARKETING_VERSION=${RELEASE_VERSION} from ${CI_TAG} ---"
  sed -i '' \
    "s/MARKETING_VERSION: .*/MARKETING_VERSION: ${RELEASE_VERSION}/" \
    project.yml
fi

echo "--- Regenerating AstroAdventure.xcodeproj ---"
xcodegen generate --spec project.yml

echo "--- Xcode Cloud post-clone setup complete ---"
