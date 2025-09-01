#!/usr/bin/env bash

# Enable right-click with two fingers
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

# Enable tap to click on trackpad
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true