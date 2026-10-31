#!/bin/zsh
# Archives the Mac app (Release) and uploads it to App Store Connect.
# 🚨 Uploading is NOT a review submission. Submitting needs the owner's explicit consent.
# Usage: ASC_KEY_ID=… ASC_ISSUER_ID=… ASC_PRIVATE_KEY_PATH=… scripts/testflight-upload-mac.sh
set -euo pipefail
cd "${0:A:h}/.."
xcodegen generate -q
ARCHIVE=build/archive-mac/hYYaFootprintInspector.xcarchive
AUTH=(-authenticationKeyPath "$ASC_PRIVATE_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
xcodebuild -project hYYaFootprintInspector.xcodeproj -scheme "hYYa Footprint Inspector Mac" -configuration Release \
  -destination "generic/platform=macOS" -archivePath "$ARCHIVE" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Apple Distribution" archive -quiet
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist scripts/ExportOptions-upload-mac.plist \
  -exportPath build/export-mac "${AUTH[@]}"
echo "Uploaded. Processing in App Store Connect takes a few minutes."
