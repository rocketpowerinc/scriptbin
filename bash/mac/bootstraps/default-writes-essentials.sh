#!/usr/bin/env bash

# Disable natural scrolling
defaults write -g com.apple.swipescrolldirection -bool false

# Remove all default apps from the Dock
defaults write com.apple.dock persistent-apps -array

# Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true

# Set Dock size
defaults write com.apple.dock tilesize -int 40

# Disable recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Enable Dock auto-hide and speed up animations
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-time-modifier -int 0
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock expose-animation-duration -float 0
defaults write com.apple.dock showhidden -bool true


# Show full POSIX path in Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Show Path Bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Always show scroll bars
defaults write -g AppleShowScrollBars -string "Always"

# Show Status Bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Show Library folder
chflags nohidden ~/Library

# Hide the favorites bar
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Apply all changes
killall Dock
killall Finder
killall SystemUIServer


# Completely disable password requirement after sleep or screensaver
defaults write com.apple.screensaver askForPassword -int 0