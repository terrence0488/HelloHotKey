#!/bin/bash
set -e
APP_NAME=HelloHotKey
APP_BUNDLE=${APP_NAME}.app
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE"/Contents/MacOS
cp Info.plist "$APP_BUNDLE"/Contents/Info.plist
swiftc \
    -module-cache-path "$PWD/.modulecache" \
    main.swift AppDelegate.swift SettingsWindowController.swift \
    -o "$APP_BUNDLE"/Contents/MacOS/"$APP_NAME" \
    -framework Cocoa -framework Carbon
echo "Built $APP_BUNDLE"