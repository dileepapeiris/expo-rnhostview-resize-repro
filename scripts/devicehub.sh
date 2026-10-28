#!/bin/sh
# Presses a control in the Xcode 27 Device Hub window of the front simulator, by its help text.
# simctl cannot fold the iPhone Duo; Device Hub's pose buttons can.
#   scripts/devicehub.sh "Open" | "Partially Open" | "Closed" | "Rotate Right" | "Rotate Left"
# Needs Accessibility permission for the terminal, and Device Hub open on the device:
#   open /Applications/Xcode.app/Contents/Applications/DeviceHub.app
HELP=$1
osascript - "$HELP" <<'APPLESCRIPT'
on run argv
  set wanted to item 1 of argv
  -- The window is briefly unavailable while a pose changes, so look again a few times.
  repeat with attempt from 1 to 8
    tell application "System Events" to tell process "DeviceHub"
      try
        -- The pose and rotate buttons sit in the window's toolbar; look in every direct child.
        repeat with g in (every UI element of window 1)
          repeat with b in (every button of g)
            try
              if (help of b) as text is wanted then
                click b
                return "clicked " & wanted
              end if
            end try
          end repeat
        end repeat
      end try
    end tell
    delay 0.5
  end repeat
  error "no control with help text " & wanted
end run
APPLESCRIPT
