#!/bin/sh

#  build.sh
#  VMware.PreferencePane
#
#  Created by Martin Løbger on 31/03/2020.
#  Copyright © 2020 ML-Consulting. All rights reserved.

xcodebuild -workspace VMware.PreferencePane.xcworkspace -scheme VMware -configuration Release -destination 'generic/platform=macOS' clean build

BUNDLE_VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "Build/Products/Release/VMware.prefPane/Contents/Info.plist")

/usr/libexec/PlistBuddy -c "Set :PACKAGES:0:PACKAGE_SETTINGS:VERSION $BUNDLE_VER" VMware.PreferencePane.pkgproj

packagesbuild --package-version "$BUNDLE_VER" VMware.PreferencePane.pkgproj