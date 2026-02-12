#!/bin/bash
# Patches SwiftyXPC source files with platform guards so they compile as empty
# on iOS/tvOS/visionOS. SwiftyXPC is a macOS-only XPC library, but Xcode
# compiles all workspace dependencies for the target platform even when the
# dependency is gated with a platform condition.
#
# Usage: bash scripts/patch-swiftyxpc-for-ios.sh <derived-data-path>

set -e

DERIVED_DATA="${1:?Usage: $0 <derived-data-path>}"
SWIFTYXPC_DIR="$DERIVED_DATA/SourcePackages/checkouts/SwiftyXPC"

if [ ! -d "$SWIFTYXPC_DIR" ]; then
  echo "SwiftyXPC not found at $SWIFTYXPC_DIR, skipping patch"
  exit 0
fi

echo "Patching SwiftyXPC at $SWIFTYXPC_DIR..."

# Update Package.swift: bump tools version and add iOS platform
sed -i '' 's|// swift-tools-version:5.7|// swift-tools-version:6.0|' \
  "$SWIFTYXPC_DIR/Package.swift"
sed -i '' 's|\.macCatalyst(.v13),|.macCatalyst(.v13),\
        .iOS(.v18),|' \
  "$SWIFTYXPC_DIR/Package.swift"

# Wrap all Swift source files with platform guards
find "$SWIFTYXPC_DIR/Sources" -name "*.swift" | while read -r file; do
  tmp=$(mktemp)
  printf '#if os(macOS) || targetEnvironment(macCatalyst)\n' > "$tmp"
  cat "$file" >> "$tmp"
  printf '\n#endif\n' >> "$tmp"
  mv "$tmp" "$file"
  echo "Patched: $(basename "$file")"
done

echo "SwiftyXPC patched for iOS compatibility"
