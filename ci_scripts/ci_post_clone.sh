#!/bin/sh
# ci_scripts/ci_post_clone.sh — Xcode Cloud post-clone hook
#
# Background: AirmatesApp.xcodeproj is gitignored because xcodegen generates
# it from project.yml on every dev/CI machine. Xcode Cloud clones the repo
# and expects to find the .xcodeproj at the repo root — without this hook,
# build fails immediately with:
#   xcodebuild: error: 'AirmatesApp.xcodeproj' does not exist.
#   Project AirmatesApp.xcodeproj does not exist at the root of the repository
#
# Apple's Xcode Cloud documentation:
#   https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
#
# Xcode Cloud build machines come with Homebrew preinstalled. We install
# xcodegen via brew (idempotent — brew skips if already installed) and then
# regenerate the .xcodeproj from project.yml.

set -e

echo "==> Installing xcodegen via Homebrew"
brew install xcodegen

echo "==> Regenerating AirmatesApp.xcodeproj from project.yml"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "==> ci_post_clone.sh complete"
