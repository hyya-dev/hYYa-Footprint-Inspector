#!/bin/zsh
# Archives a Release build and uploads it to App Store Connect (TestFlight).
# 🚨 Uploading is NOT a review submission. Submitting needs the owner's explicit consent.
# Usage: ASC_KEY_ID=… ASC_ISSUER_ID=… ASC_PRIVATE_KEY_PATH=… scripts/testflight-upload.sh
set -euo pipefail
cd "${0:A:h}/.."
xcodegen generate -q
ARCHIVE=build/archive/hYYaFootprintInspector.xcarchive
AUTH=(-authenticationKeyPath "$ASC_PRIVATE_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
xcodebuild -project hYYaFootprintInspector.xcodeproj -scheme "hYYa Footprint Inspector" -configuration Release \
  -destination "generic/platform=iOS" -archivePath "$ARCHIVE" -allowProvisioningUpdates "${AUTH[@]}" archive -quiet
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist scripts/ExportOptions-upload.plist \
  -exportPath build/export "${AUTH[@]}"
echo "Uploaded. Processing in App Store Connect takes a few minutes."
