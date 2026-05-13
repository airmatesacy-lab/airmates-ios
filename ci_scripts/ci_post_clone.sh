#!/bin/sh
# ci_scripts/ci_post_clone.sh — Xcode Cloud post-clone hook
#
# Two problems this script solves:
#
# 1. AirmatesApp.xcodeproj is gitignored because xcodegen generates it from
#    project.yml. Xcode Cloud expects the .xcodeproj at the repo root, so we
#    install xcodegen and regenerate.
#
# 2. Xcode Cloud disables automatic Swift Package Manager dependency
#    resolution for build reproducibility/security and requires a committed
#    Package.resolved. Our Package.resolved would normally live inside the
#    .xcodeproj (which is gitignored). We store the canonical Package.resolved
#    at spm/Package.resolved in the repo root and copy it into the regenerated
#    .xcodeproj here.
#
# When the Stripe SDK version is bumped in project.yml:
#   1. Locally: xcodegen generate && xcodebuild -resolvePackageDependencies
#   2. cp AirmatesApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved spm/Package.resolved
#   3. git add spm/Package.resolved && commit
#
# Apple docs:
#   https://developer.apple.com/documentation/xcode/writing-custom-build-scripts

set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "==> Installing xcodegen via Homebrew"
brew install xcodegen

echo "==> Regenerating AirmatesApp.xcodeproj from project.yml"
xcodegen generate

echo "==> Restoring committed Package.resolved into the regenerated xcodeproj"
SPM_DIR="AirmatesApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
mkdir -p "$SPM_DIR"
cp spm/Package.resolved "$SPM_DIR/Package.resolved"

echo "==> ci_post_clone.sh complete"
