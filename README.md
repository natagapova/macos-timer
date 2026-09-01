# macos-timer

menu bar timer and pomodoro for macOS.

timer screen inspired by [onigiri](https://apps.apple.com/us/app/onigiri-minimal-timer/id1639917298). pomodoro is my own.

## install

download the latest release, unzip, move to Applications, then in Terminal:

```bash
xattr -cr /Applications/macos-timer.app
```

open the app. it lives in the menu bar.

macOS 13+. click the menu bar label to open. click outside to close. ⋯ → quit to exit.

## build from source

```bash
killall macos-timer 2>/dev/null; xcodebuild -project macos-timer.xcodeproj -scheme macos-timer -configuration Debug -derivedDataPath build CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=NO build && open build/Build/Products/Debug/macos-timer.app
```
