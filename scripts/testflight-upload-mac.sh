#!/bin/zsh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Archives the Mac app (Release) and uploads it to App Store Connect.
# 🚨 Uploading is NOT a review submission. Submitting needs explicit human approval.
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
