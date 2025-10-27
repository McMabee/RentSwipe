# RentSwipe iOS App Template

This is a starting point for the RentSwipe iOS application, built with SwiftUI and organized for rapid iteration on the Tinder-style housing experience described in the specification.

## Project layout

- `RentSwipe.xcodeproj`: Xcode project preconfigured for an iPhone SwiftUI app with unit and UI test targets.
- `RentSwipe/`: Application sources, assets, preview content, and configuration files.
- `RentSwipeTests/`: Unit tests you can extend as you build out features.
- `RentSwipeUITests/`: UI test target wired for basic launch verification.

## Getting started

1. Open `RentSwipe.xcodeproj` in Xcode (15.0 or newer recommended).
2. Update the team and bundle identifier in the project settings so you can run on a device.
3. Replace the placeholder UI in `ContentView.swift` with the swipe experience, data models, and navigation flow you have in mind.
4. Drop in real app icon assets inside `Assets.xcassets/AppIcon.appiconset`.
5. Run the provided unit and UI test targets (`⌘U`) to keep regressions in check.

From here you can add feature-specific modules, shared UI components, networking, persistence, and more as you flesh out the RentSwipe experience.
