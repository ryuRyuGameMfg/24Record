#!/bin/bash

echo "Testing compilation of WeeklyMonthlyView.swift..."
echo "================================================"

# Change to project directory
cd /Users/okamotoryuya/24Record

# Try to compile just the Swift file to check for syntax errors
swiftc -parse -target arm64-apple-ios15.0 \
    -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks \
    -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include \
    -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk \
    24Record/Views/Statistics/WeeklyMonthlyView.swift 2>&1 | grep -E "(error:|warning:)" | head -20

echo ""
echo "If no errors shown above, the syntax is correct."
echo "Now open Xcode and build the project to check for full compilation."