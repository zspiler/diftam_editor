# poc

### How to run 

#### Web
`flutter run -d chrome`

#### MacOS

`flutter run -d MacOS`

To run the MacOS app need to have XCode and some other tools installed: 

https://docs.flutter.dev/get-started/install/macos/desktop

In my case, I also had to have at least one Simulator installed before 
the MacOS app could be run (?).

*TLDR*

`sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

`sudo xcodebuild -runFirstLaunch`

`brew install cocoapods` (if using Homebrew)

*Something not working?*

`flutter doctor`