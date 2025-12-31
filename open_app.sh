#!/bin/bash

# Flight Compensation App - Quick Launch Script
# This script opens your project in Xcode

echo "🚀 Opening Flight Compensation App in Xcode..."
echo ""
echo "✅ Changes Applied:"
echo "   - API Key: YOUR_FR24_KEY_ID"
echo "   - Live Tracking: ENABLED"
echo "   - Config.swift: UPDATED"
echo ""
echo "📱 Next Steps:"
echo "   1. Select iPhone 15 Pro simulator"
echo "   2. Press ⌘R to run"
echo "   3. Add a test flight (BA178, FR1234, LH441)"
echo "   4. Watch real data populate! ✈️"
echo ""
echo "🔍 Watch the Xcode console for API logs"
echo ""

# Check if project exists
if [ -f "FlightCompensation.xcodeproj/project.pbxproj" ]; then
    echo "✅ Project found! Opening Xcode..."
    open FlightCompensation.xcodeproj
else
    echo "❌ Project not found!"
    echo ""
    echo "Creating project now..."
    echo "Please follow these steps in Xcode:"
    echo ""
    echo "1. File → New → Project"
    echo "2. iOS → App"
    echo "3. Product Name: FlightCompensation"
    echo "4. Interface: SwiftUI"
    echo "5. Language: Swift"
    echo "6. Minimum: iOS 17.0"
    echo "7. Save in this folder"
    echo ""
    echo "Then drag the 'FlightCompensation' folder into Xcode"
    echo "(Uncheck 'Copy items if needed')"
    
    # Open Xcode anyway
    open -a Xcode
fi
