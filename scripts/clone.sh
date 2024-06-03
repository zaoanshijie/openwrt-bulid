#!/bin/bash

cd $GITHUB_WORKSPACE
if [[ $WRT_URL == *"lede"* ]]; then
  echo "clone lede src"
  git clone $WRT_URL -b $WRT_BRANCH build

elif [[ $WRT_URL == *"immortalwrt"* ]]; then
  echo "clone immortalwrt src"
  git clone $WRT_URL -b master build

elif [[ $WRT_URL == *"openwrt"* ]]; then
  echo "clone openwrt src"
  git clone $WRT_URL -b v23.05.3 build
fi
