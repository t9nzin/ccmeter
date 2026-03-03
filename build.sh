#!/bin/bash
set -e

echo "Building CCMeter..."
swift build -c release

APP_DIR="CCMeter.app/Contents/MacOS"
mkdir -p "$APP_DIR"

cp .build/release/CCMeter "$APP_DIR/CCMeter"
cp Info.plist CCMeter.app/Contents/Info.plist

echo "Built CCMeter.app successfully"
