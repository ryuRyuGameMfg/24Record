#!/bin/bash

echo "Checking for compilation issues in 24Record project..."
echo "=================================================="

# Check for references to deleted types
echo -e "\n1. Checking for references to deleted Legacy types..."
grep -r "TimeBlock\|Category\|Tag" --include="*.swift" /Users/okamotoryuya/24Record/24Record | grep -v "SDTimeBlock\|SDCategory\|SDTag\|TaskPattern" | head -20

# Check for references to deleted TimeTrackingViewModel
echo -e "\n2. Checking for references to deleted TimeTrackingViewModel..."
grep -r "TimeTrackingViewModel" --include="*.swift" /Users/okamotoryuya/24Record/24Record | grep -v "SwiftDataTimeTrackingViewModel" | head -20

# Check for missing imports
echo -e "\n3. Checking files that use SD types without SwiftData import..."
for file in /Users/okamotoryuya/24Record/24Record/**/*.swift; do
    if grep -q "SDTimeBlock\|SDCategory\|SDTag" "$file" 2>/dev/null; then
        if ! grep -q "import SwiftData" "$file" 2>/dev/null; then
            echo "Missing SwiftData import in: $file"
        fi
    fi
done

echo -e "\n=================================================="
echo "Check complete!"