#!/bin/sh
# Builds a universal Zikr.app and zips it for a GitHub release.
set -e
cd "$(dirname "$0")/.."
./scripts/build-app.sh --universal
rm -f build/Zikr.zip
ditto -c -k --keepParent build/Zikr.app build/Zikr.zip
echo "Packaged build/Zikr.zip"
