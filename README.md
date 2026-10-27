# RNHostView content snaps to its final size during an animated SwiftUI resize

Reproduction for https://github.com/expo/expo/issues/52396 on iOS, with frame-by-frame
measurements. Rebuilt from the reporter's
[rnhostview-resize-repro](https://github.com/swood09/rnhostview-resize-repro), Screen 1, as a
single-screen app without Expo Router.

Versions: Expo SDK 58, `@expo/ui` 58.0.23, React Native 0.88, iOS 26.5 simulator (iPhone 17),
Xcode 26.6.

## Run

```sh
npm install
npx expo run:ios      # development build, iOS simulator
```

## What the app does

Two copies of the same card, one built in SwiftUI (the control) and one built in React Native
inside `RNHostView`, sit in SwiftUI frames whose width animates between 200 and 360 points over
0.8 s (`frame({ width })` + `animation(Animation.easeInOut({ duration: 0.8 }), wide)`).

The **Make wide / Make narrow** button toggles the width. The app also toggles on its own at
3, 6, 9 and 12 s after launch so a screenshot loop can run without tapping, and it logs every
`onLayout` the hosted React Native view receives, with the time since the toggle.

