#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$ROOT_DIR/.build"
DERIVED_DATA="$BUILD_ROOT/DerivedData"
BUILD_LOG="$BUILD_ROOT/last-build.log"

mkdir -p "$BUILD_ROOT"

WORKSPACE="$(find "$ROOT_DIR" -maxdepth 1 -name '*.xcworkspace' -print -quit)"
PROJECT="$(find "$ROOT_DIR" -maxdepth 1 -name '*.xcodeproj' -print -quit)"

if [[ -n "$WORKSPACE" ]]; then
  CONTAINER_ARGS=(-workspace "$WORKSPACE")
elif [[ -n "$PROJECT" ]]; then
  CONTAINER_ARGS=(-project "$PROJECT")
else
  echo "error: no Xcode project or workspace found under $ROOT_DIR" >&2
  exit 1
fi

SCHEME="$(xcodebuild "${CONTAINER_ARGS[@]}" -list -json | /usr/bin/python3 -c '
import json, sys
payload = json.load(sys.stdin)
container = payload.get("workspace") or payload.get("project") or {}
schemes = container.get("schemes", [])
preferred = [name for name in schemes if "widget" not in name.lower()]
if not preferred:
    raise SystemExit("No app scheme found")
print(preferred[0])
')"

APP_NAME="$SCHEME"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

set +e
set -o pipefail
xcodebuild \
  "${CONTAINER_ARGS[@]}" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  build 2>&1 | tee "$BUILD_LOG"
BUILD_STATUS=${PIPESTATUS[0]}
set -e

if [[ $BUILD_STATUS -ne 0 ]]; then
  echo >&2
  echo "First actionable build error:" >&2
  /usr/bin/grep -Em1 '(^|: )(error:|CodeSign error|Provisioning profile|No profiles for|Signing for)' "$BUILD_LOG" >&2 || \
    tail -40 "$BUILD_LOG" >&2
  exit "$BUILD_STATUS"
fi

APP_BUNDLE="$(find "$DERIVED_DATA/Build/Products/Debug" -maxdepth 1 -type d -name '*.app' -print -quit)"
if [[ -z "$APP_BUNDLE" ]]; then
  echo "error: build succeeded but no app bundle was found" >&2
  exit 1
fi

INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO_PLIST")"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"

register_current_widget_extension() {
  local widget_bundle widget_info widget_id widget_executable registered_plugin registered_app
  local registered_paths registration_count lsregister

  widget_bundle="$(find "$APP_BUNDLE/Contents/PlugIns" -maxdepth 1 -type d -name '*.appex' -print -quit 2>/dev/null || true)"
  [[ -n "$widget_bundle" ]] || return 0

  widget_info="$widget_bundle/Contents/Info.plist"
  widget_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$widget_info")"
  widget_executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$widget_info")"
  lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

  # Xcode and ad-hoc validation builds can leave several extensions with the
  # same bundle identifier registered. WidgetKit may otherwise keep launching
  # an older binary even after a successful build.
  while IFS= read -r registered_plugin; do
    [[ "$registered_plugin" == /* ]] || continue
    [[ "$registered_plugin" == "$widget_bundle" ]] && continue
    /usr/bin/pluginkit -r "$registered_plugin" >/dev/null 2>&1 || true
    registered_app="${registered_plugin%%/Contents/PlugIns/*}"
    "$lsregister" -u "$registered_app" >/dev/null 2>&1 || true
  done < <(/usr/bin/pluginkit -m -A -D -v -i "$widget_id" 2>/dev/null | /usr/bin/awk -F '\t' 'NF > 1 { print $NF }')

  /usr/bin/pkill -f "/Contents/PlugIns/.*/Contents/MacOS/$widget_executable" >/dev/null 2>&1 || true
  "$lsregister" -f -R -trusted "$APP_BUNDLE" >/dev/null
  /usr/bin/pluginkit -a "$widget_bundle"
  /usr/bin/pluginkit -e use -i "$widget_id"

  if [[ "$MODE" == "--verify" || "$MODE" == "verify" ]]; then
    registered_paths="$(/usr/bin/pluginkit -m -A -D -v -i "$widget_id" 2>/dev/null | /usr/bin/awk -F '\t' 'NF > 1 { print $NF }')"
    registration_count="$(printf '%s\n' "$registered_paths" | /usr/bin/grep -c '^/' || true)"
    if [[ "$registration_count" -ne 1 || "$registered_paths" != "$widget_bundle" ]]; then
      echo "error: expected only the current Widget extension to be registered" >&2
      printf '%s\n' "$registered_paths" >&2
      exit 1
    fi
    echo "Verified Widget registration: $widget_id -> $widget_bundle"
  fi
}

register_current_widget_extension

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --verify|verify)
    open_app
    for _ in {1..20}; do
      if pgrep -x "$EXECUTABLE_NAME" >/dev/null; then
        echo "Verified running process: $EXECUTABLE_NAME"
        exit 0
      fi
      sleep 0.25
    done
    echo "error: $EXECUTABLE_NAME did not start" >&2
    exit 1
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$EXECUTABLE_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  *)
    echo "usage: $0 [run|--verify|--logs|--telemetry|--debug]" >&2
    exit 2
    ;;
esac
