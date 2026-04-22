#!/usr/bin/env bash
# Build a release iOS IPA (must run on macOS with Xcode).
# Usage: ./scripts/build_ios.sh
#
# Requires a valid Apple Developer account and provisioning profile.
# Set APPLE_TEAM_ID in your environment before running.
set -euo pipefail

echo "==> flutter build ios --release --no-codesign"
flutter build ios --release --no-codesign

echo "==> Archive via xcodebuild"
xcodebuild -workspace ios/Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -archivePath build/ios/Runner.xcarchive \
           archive | xcpretty

echo "==> Export IPA"
xcodebuild -exportArchive \
           -archivePath build/ios/Runner.xcarchive \
           -exportPath build/ios/ipa \
           -exportOptionsPlist ios/ExportOptions.plist | xcpretty

echo "==> Done: build/ios/ipa/Runner.ipa"
