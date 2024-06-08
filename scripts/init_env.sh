#!/bin/bash

echo "DEVICE_NAME=x86_64" >>$GITHUB_ENV
if [[ $WRT_URL == *"lede"* ]]; then
  echo "BUILD_DIR=lede" >>"$GITHUB_ENV"
  echo "REPOSITORY=lede" >>"$GITHUB_ENV"

elif [[ $WRT_URL == *"immortalwrt"* ]]; then
  echo "BUILD_DIR=immortalwrt" >>"$GITHUB_ENV"
  echo "REPOSITORY=immortalwrt" >>"$GITHUB_ENV"

elif [[ $WRT_URL == *"openwrt"* ]]; then
  echo "BUILD_DIR=openwrt" >>"$GITHUB_ENV"
  echo "REPOSITORY=openwrt" >>"$GITHUB_ENV"
else
  echo "not supported : ${WRT_URL}"
  exit -1
fi
