#!/bin/bash

cd "$GITHUB_WORKSPACE/build"

rm -f ./.config*
if [[ $WRT_URL == *"lede"* ]]; then
  echo "replace lede config lede"
  cp ${GITHUB_WORKSPACE}/config/x86_64/lede_config ./.config

elif [[ $WRT_URL == *"immortalwrt"* ]]; then
  echo "replace immortalwrt config lede"
  cp ${GITHUB_WORKSPACE}/config/x86_64/immortalwrt_config ./.config

elif [[ $WRT_URL == *"openwrt"* ]]; then
  echo "replace openwrt config lede"
  cp ${GITHUB_WORKSPACE}/config/x86_64/openwrt_config ./.config
fi
