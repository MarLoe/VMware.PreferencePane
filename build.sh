#!/bin/sh

#  build.sh
#  VMware.PreferencePane
#
#  Created by Martin Løbger on 31/03/2020.
#  Copyright © 2020 ML-Consulting. All rights reserved.

xcodebuild -workspace VMware.PreferencePane.xcworkspace -scheme VMware -configuration Release clean build

BUNDLE_VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "Build/Products/Release/VMware.prefPane/Contents/Info.plist")

packagesbuild --package-version "$BUNDLE_VER" VMware.prefPane.pkgproj