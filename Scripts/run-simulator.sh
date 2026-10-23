#!/bin/zsh
set -euo pipefail

orbit_root="$(cd "$(dirname "$0")/.." && pwd)"
orbit_device="$(xcrun simctl list devices available -j | python3 -c '
import json,sys
choices=[]
for runtime,devices in json.load(sys.stdin)["devices"].items():
    if "xrOS-" not in runtime: continue
    version=tuple(map(int,runtime.split("xrOS-")[1].split("-")))
    for device in devices:
        if "Vision Pro" in device["name"]:
            choices.append((version,device["state"]=="Booted",device["udid"]))
if not choices:
    sys.exit("Install a visionOS simulator in Xcode > Settings > Components first.")
print(max(choices)[2])
')"

orbit_action=build
if [[ "${1:-}" == "--test" ]]; then orbit_action=test; fi
xcodebuild -project "$orbit_root/OrbitLite.xcodeproj" -scheme OrbitLite \
    -configuration Debug -destination "platform=visionOS Simulator,id=$orbit_device" \
    -derivedDataPath "$orbit_root/DerivedData" CODE_SIGNING_ALLOWED=NO "$orbit_action"

xcrun simctl boot "$orbit_device" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$orbit_device" -b
xcrun simctl install "$orbit_device" "$orbit_root/DerivedData/Build/Products/Debug-xrsimulator/OrbitLite.app"
orbit_app="$orbit_root/DerivedData/Build/Products/Debug-xrsimulator/OrbitLite.app"
orbit_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$orbit_app/Info.plist")"
xcrun simctl launch "$orbit_device" "$orbit_bundle_id"
orbit_developer_dir="$(xcode-select -p)"
if [[ -d "$orbit_developer_dir/../Applications/DeviceHub.app" ]]; then
    open -a "$orbit_developer_dir/../Applications/DeviceHub.app"
else
    open -a Simulator
fi
