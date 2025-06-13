#!/bin/bash

echo "Cleaning 24Record project..."
echo "============================"

# Clean Xcode build
echo "1. Cleaning Xcode build folder..."
xcodebuild clean -project /Users/okamotoryuya/24Record/24Record.xcodeproj -scheme 24Record 2>/dev/null

# Remove derived data
echo "2. Removing derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/24Record-*

# Remove Swift module cache
echo "3. Removing Swift module cache..."
find /Users/okamotoryuya/24Record -name "*.swiftinterface" -o -name "*.swiftmodule" -o -name "*.swiftsourceinfo" | xargs rm -f 2>/dev/null

# Remove build folder
echo "4. Removing build folder..."
rm -rf /Users/okamotoryuya/24Record/build

echo ""
echo "Clean complete! Please try building the project again in Xcode."
echo ""
echo "If errors persist, try:"
echo "1. Restart Xcode"
echo "2. Delete ~/Library/Developer/Xcode/DerivedData completely"
echo "3. Clean build folder (Cmd+Shift+K)"
echo "4. Build again (Cmd+B)"