#!/bin/bash

echo "Performing deep clean of Xcode caches..."
echo "======================================="

# Kill Xcode if running
echo "1. Closing Xcode if running..."
killall Xcode 2>/dev/null || true

# Clean DerivedData
echo "2. Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/24Record-*
rm -rf ~/Library/Developer/Xcode/DerivedData/CompilationCache.noindex

# Clean build folder
echo "3. Cleaning build folder..."
rm -rf /Users/okamotoryuya/24Record/build

# Clean module cache
echo "4. Cleaning module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Clean Xcode caches
echo "5. Cleaning Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Reset simulator (if needed)
echo "6. Resetting simulator caches..."
xcrun simctl shutdown all 2>/dev/null || true
rm -rf ~/Library/Developer/CoreSimulator/Caches/* 2>/dev/null || true

# Clean SPM cache
echo "7. Cleaning Swift Package Manager cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm

echo ""
echo "Deep clean complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Open the 24Record project"
echo "3. Wait for indexing to complete"
echo "4. Build the project (Cmd+B)"
echo ""
echo "If the error persists, try:"
echo "- Restart your Mac"
echo "- Check disk for errors using Disk Utility"
echo "- Verify file permissions"