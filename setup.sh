#!/bin/bash

# Setup script for Flight Compensation iOS App
# This script helps set up the Xcode project

echo "🚀 Setting up Flight Compensation iOS App..."
echo ""

# Check if we're in the right directory
if [ ! -d "FlightCompensation" ]; then
    echo "❌ Error: FlightCompensation directory not found!"
    exit 1
fi

echo "✅ Found FlightCompensation directory"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Open Xcode"
echo "2. Create a new project:"
echo "   - Choose 'iOS' > 'App'"
echo "   - Product Name: FlightCompensation"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Minimum iOS: 17.0"
echo ""
echo "3. Save the project in this directory:"
echo "   $(pwd)"
echo ""
echo "4. In Xcode, delete the default ContentView.swift if it exists"
echo ""
echo "5. Drag the entire 'FlightCompensation' folder into Xcode"
echo "   Make sure 'Copy items if needed' is UNCHECKED"
echo "   Make sure 'Create groups' is selected"
echo ""
echo "6. In the project settings:"
echo "   - Set Minimum Deployments to iOS 17.0"
echo "   - Make sure SwiftUI is enabled"
echo ""
echo "7. Build and run (⌘R)"
echo ""
echo "✨ Your app should now be ready to run!"


