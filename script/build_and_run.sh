#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$ROOT_DIR/.build"
# Widget extensions launched by ExtensionKit must live outside privacy-protected
# Desktop/Documents build folders. Use Xcode's standard per-user DerivedData
# location so macOS can validate and launch the signed extension reliably.
DERIVED_DATA="${IELTSGLANCE_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/IELTSGlance-Codex}"
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
# One-time migration cleanup for builds produced before the IELTSGlance rename.
pkill -x "GREGlance" >/dev/null 2>&1 || true

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
  local widget_bundle widget_info widget_id widget_executable widget_debug_dylib
  local registered_plugin registered_app registered_info registered_id registered_widget service
  local registered_paths registration_count lsregister

  widget_bundle="$(find "$APP_BUNDLE/Contents/PlugIns" -maxdepth 1 -type d -name '*.appex' -print -quit 2>/dev/null || true)"
  [[ -n "$widget_bundle" ]] || return 0

  widget_info="$widget_bundle/Contents/Info.plist"
  widget_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$widget_info")"
  widget_executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$widget_info")"
  widget_debug_dylib="$widget_bundle/Contents/MacOS/${widget_executable}.debug.dylib"
  lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

  verify_interaction_metadata() {
    local bundle metadata
    bundle="$1"
    metadata="$bundle/Contents/Resources/Metadata.appintents/extract.actionsdata"

    if [[ ! -f "$metadata" ]]; then
      echo "error: App Intents metadata is missing from $bundle" >&2
      exit 1
    fi
    if ! /usr/bin/grep -aq 'ReplaceWordIntent' "$metadata"; then
      echo "error: ReplaceWordIntent is missing from App Intents metadata in $bundle" >&2
      exit 1
    fi
    if ! /usr/bin/grep -aq 'ShuffleAllWordsIntent' "$metadata"; then
      echo "error: ShuffleAllWordsIntent is missing from App Intents metadata in $bundle" >&2
      exit 1
    fi
    if ! /usr/bin/grep -aq 'selectedPackIDsPayload' "$metadata"; then
      echo "error: Widget interaction metadata still uses an unsafe collection payload in $bundle" >&2
      exit 1
    fi
  }

  # WidgetKit interactive actions must be discoverable from both the containing
  # app and the extension. If either side is absent, macOS cannot archive the
  # button LinkAction and replaces the entire Widget with a skeleton view.
  verify_interaction_metadata "$APP_BUNDLE"
  verify_interaction_metadata "$widget_bundle"

  if ! /usr/bin/codesign -d --entitlements - --xml "$widget_bundle" 2>&1 | \
      /usr/bin/grep -q '<key>com.apple.security.app-sandbox</key>'; then
    echo "error: Widget extension is missing the App Sandbox entitlement" >&2
    exit 1
  fi

  # Xcode's debug-dylib mode strips entitlements from the binary that
  # ExtensionKit actually launches, so interactive Widget intents silently fail.
  if [[ -e "$widget_debug_dylib" ]]; then
    echo "error: Widget Debug dylib is enabled; set ENABLE_DEBUG_DYLIB=NO for the Widget Debug configuration" >&2
    exit 1
  fi

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

  # LaunchServices can retain an unsigned test-host copy even when pluginkit no
  # longer lists its extension. Remove other DerivedData copies of this app so
  # App Intents cannot be routed to a stale or unsigned binary.
  while IFS= read -r -d '' registered_app; do
    [[ "$registered_app" == "$APP_BUNDLE" ]] && continue
    registered_info="$registered_app/Contents/Info.plist"
    [[ -f "$registered_info" ]] || continue
    registered_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$registered_info" 2>/dev/null || true)"
    [[ "$registered_id" == "$BUNDLE_ID" ]] || continue
    registered_widget="$(find "$registered_app/Contents/PlugIns" -maxdepth 1 -type d -name '*.appex' -print -quit 2>/dev/null || true)"
    [[ -z "$registered_widget" ]] || /usr/bin/pluginkit -r "$registered_widget" >/dev/null 2>&1 || true
    "$lsregister" -u "$registered_app" >/dev/null 2>&1 || true
  done < <(find "$HOME/Library/Developer/Xcode/DerivedData" "$BUILD_ROOT" \
    -type d -name '*.app' -path '*/Build/Products/*' -print0 -prune 2>/dev/null)

  /usr/bin/pkill -f "/Contents/PlugIns/.*/Contents/MacOS/$widget_executable" >/dev/null 2>&1 || true
  /usr/bin/pkill -f "/Contents/PlugIns/.*/Contents/MacOS/GREGlanceWidgetExtension" >/dev/null 2>&1 || true

  # Refresh user-level discovery caches before registering the current build.
  # These services restart automatically; no system settings are changed.
  for service in linkd extensionkitservice chronod; do
    /usr/bin/killall "$service" >/dev/null 2>&1 || true
  done
  for _ in {1..20}; do
    pgrep -x linkd >/dev/null && pgrep -x chronod >/dev/null && break
    sleep 0.25
  done

  # Re-register even when the bundle path is unchanged. ExtensionKit caches
  # signing metadata by bundle identifier and can otherwise retain a stale
  # record that incorrectly reports the sandbox entitlement as missing.
  /usr/bin/pluginkit -r "$widget_bundle" >/dev/null 2>&1 || true
  "$lsregister" -u "$APP_BUNDLE" >/dev/null 2>&1 || true
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
