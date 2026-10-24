#!/bin/zsh
# Captures the seven store screens on this project's iPhone Duo Simulator from launch switches
# alone (no taps), in whatever pose Device Hub has it in. Sample data only.
#   scripts/capture-duo.sh <out-dir> [display: outer|inner]
set -euo pipefail
cd "${0:A:h}/.."
OUT=$1; WHICH=${2:-outer}
UDID=$(xcrun simctl list devices | grep "fi-iPhone-Duo" | grep -oE "[0-9A-F-]{36}")
APP="build/dd/Build/Products/Debug-iphonesimulator/hYYa Footprint Inspector.app"
BID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP/Info.plist")
# The display to photograph, by its pixel width: outer 1398 (2034 sideways), inner 2007 (2853).
DISP=$(xcrun simctl io $UDID enumerate | awk -v want=$WHICH '
  /UUID:/ {u=$2} /Default width:/ {w=$3; if ((want=="outer" && (w==1398||w==2034)) || (want=="inner" && (w==2007||w==2853))) {print u; exit}}')
mkdir -p "$OUT"
xcrun simctl install $UDID "$APP"
shot() { local name=$1; shift
  xcrun simctl terminate $UDID $BID 2>/dev/null || true
  xcrun simctl launch $UDID $BID -sampleData "$@" >/dev/null
  sleep 7
  xcrun simctl io $UDID screenshot --display="$DISP" "$OUT/$name.png" >/dev/null 2>&1
  echo "$name"
}
shot store-01-home
shot store-02-results -autoScan
shot store-04-finding -autoScan -openFinding boot-time
shot store-05-sensitive -startTab sensitive -sensitiveCategories dating,health,circumvention
shot store-06-checkup -startTab checkup
shot store-08-tracker -startTab tracker
shot store-09-fix -autoScan -openFix
