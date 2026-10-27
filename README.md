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

## Expected

Both cards resize smoothly: the photo, the wrapping text and the button grow with the frame.

## Actual

The SwiftUI card interpolates. The React Native card lays out at its **final** size in the first
frame, while its frame is still at the starting width, so the content overflows the frame and
the frame then catches up.

![mid-animation](media/mid-animation-3920ms.png)

## Measurements on 10/27/26, narrow → wide

`scripts/capture.sh` takes a screenshot burst across the first two automatic toggles and
`scripts/measure.py` reads the width of each card's grey background and blue button out of
every frame (pixels at 3x; 600 px = 200 pt, 1080 px = 360 pt).

| ms after launch | SwiftUI card | SwiftUI button | RN card | RN button |
| --- | --- | --- | --- | --- |
| 3524 | 600 | 512 | 600 | 506 |
| 3649 | 600 | 512 | 600 | **996** |
| 3783 | 634 | 546 | 634 | 996 |
| 3920 | 725 | 638 | 726 | 996 |
| 4050 | 840 | 752 | 840 | 996 |
| 4176 | 954 | 866 | 954 | 996 |
| 4306 | 1046 | 958 | 1046 | 996 |
| 4439 | 1079 | 992 | 1080 | 996 |

The SwiftUI button widens over six frames. The React Native button is at its final width in the
first frame, 396 px wider than the card it sits in.

Metro log for the same toggles: exactly one `onLayout` per toggle, already at the destination
width, and nothing during the 800 ms animation.

```
[52396] AUTO-TOGGLE 1 (t=3090)
[52396] onLayout width=360.0 height=260.0 +32ms after toggle (t=3122)
[52396] AUTO-TOGGLE 2 (t=6089)
[52396] onLayout width=200.0 height=260.0 +22ms after toggle (t=6111)
```

