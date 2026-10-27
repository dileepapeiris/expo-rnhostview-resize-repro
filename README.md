# RNHostView content snaps to its final size during an animated SwiftUI resize

Reproduction for https://github.com/expo/expo/issues/52396 on iOS, with frame-by-frame
measurements. Rebuilt from the reporter's
[rnhostview-resize-repro](https://github.com/swood09/rnhostview-resize-repro), Screen 1, as a
single-screen app without Expo Router.

Versions: Expo SDK 58, `@expo/ui` 58.0.23, React Native 0.88, iOS 26.5 simulator (iPhone 17),
Xcode 26.6.

