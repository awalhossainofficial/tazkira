#!/bin/sh
# Builds Zikr.zip and its release notes. With --publish it also creates the GitHub release.
# Usage: ./scripts/package-release.sh [--publish] [whats-new.md]
set -e
cd "$(dirname "$0")/.."

PUBLISH=
if [ "$1" = "--publish" ]; then PUBLISH=1; shift; fi
WHATS_NEW=$1

# The release is tagged on GitHub's copy, so it must match what we build here.
if [ -n "$PUBLISH" ]; then
  git fetch -q origin
  if [ -n "$(git status --porcelain)" ] || [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then
    echo "Commit and push your changes before publishing a release." >&2
    exit 1
  fi
fi

./scripts/build-app.sh --universal
rm -f build/Zikr.zip
ditto -c -k --keepParent build/Zikr.app build/Zikr.zip

VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' build/Zikr.app/Contents/Info.plist)
{
  if [ -n "$WHATS_NEW" ]; then cat "$WHATS_NEW"; echo; fi
  cat docs/release-install.md
} > build/release-notes.md
echo "Packaged build/Zikr.zip and build/release-notes.md for version $VERSION"

if [ -n "$PUBLISH" ]; then
  gh release create "v$VERSION" build/Zikr.zip --title "Zikr $VERSION" \
    --notes-file build/release-notes.md --target "$(git rev-parse HEAD)"
fi
