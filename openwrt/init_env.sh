#!/bin/bash

echo "init openwrt build env"
sudo -E apt-mark hold grub-efi-amd64-signed
sudo apt-get update -y
sudo apt-get full-upgrade -y
sudo apt-get install -y build-essential clang llvm flex g++ gawk gcc-multilib gettext \
  git libncurses-dev libssl-dev python3-distutils python3-pyelftools python3-setuptools \
  libpython3-dev rsync unzip zlib1g-dev swig aria2 jq subversion qemu-utils ccache rename \
  libelf-dev device-tree-compiler libgnutls28-dev coccinelle libgmp3-dev libmpc-dev libfuse-dev \
  libnetsnmptrapd40 nano bison g++-multilib file wget sudo time subversion bash make patch xz-utils \
  curl libsnmp-dev liblzma-dev libpam0g-dev cpio tzdata cmake

UPX_REV="4.1.0"
curl -fLO "https://github.com/upx/upx/releases/download/v${UPX_REV}/upx-$UPX_REV-amd64_linux.tar.xz"
tar -Jxf "upx-$UPX_REV-amd64_linux.tar.xz"
sudo rm -rf "/usr/bin/upx" "/usr/bin/upx-ucl"
sudo cp -fp "upx-$UPX_REV-amd64_linux/upx" "/usr/bin/upx-ucl"
sudo chmod 0755 "/usr/bin/upx-ucl"
sudo ln -svf "/usr/bin/upx-ucl" "/usr/bin/upx"

sudo apt-get clean
sudo apt-get autoclean --purge
rm -rf /var/lib/apt/lists/*
sudo timedatectl set-timezone "$TZ"
