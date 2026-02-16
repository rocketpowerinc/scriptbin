#!/usr/bin/env bash

sudo apt update && sudo apt upgrade
sudo apt install golang-go
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.bashrc
sudo apt update && sudo apt install -y git gh jq make bat tmux curl wget glow gum
go install -v github.com/rocketpowerinc/go-pwr/cmd/go-pwr@latest
source ~/.bashrc
go-pwr