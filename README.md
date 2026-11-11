# iOS app
SwiftUI app built from the phone. `project.yml` describes the Xcode project (XcodeGen); put Swift files in `App/`.
Do not add or edit a `.xcodeproj` and keep `PRODUCT_BUNDLE_IDENTIFIER` as is: the build sets it.
Name: set `INFOPLIST_KEY_CFBundleDisplayName` in `project.yml` to the app's real name (keep it under 12 characters).
Icon: create `icon.json` at the repo root, e.g. `{"symbol": "gamecontroller.fill", "colors": ["#FF6B6B", "#FFB347"]}` (any SF Symbol name, two hex colors). The build renders it as the app icon.