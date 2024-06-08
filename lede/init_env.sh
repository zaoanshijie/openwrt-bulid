#!/bin/bash

echo "init lede build env"
sudo -E apt-mark hold grub-efi-amd64-signed
sudo apt-get update -y
sudo apt-get full-upgrade -y
sudo apt-get install -y ack antlr3 asciidoc autoconf \
  automake autopoint binutils bison build-essential bzip2 \
  ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext \
  gcc-multilib g++-multilib git gperf haveged help2man intltool libc6-dev-i386 \
  libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev \
  libncurses-dev libpython3-dev libreadline-dev libssl-dev libtool \
  lrzsz mkisofs msmtp ninja-build p7zip p7zip-full patch pkgconf python2.7 \
  python3 python3-pyelftools python3-setuptools qemu-utils rsync scons \
  squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget \
  xmlto xxd zlib1g-dev libpam0g-dev cpio tzdata cmake libnetsnmptrapd40 nano file \
  time xz-utils libsnmp-dev
# libncursesw5-dev

sudo apt-get clean
sudo apt-get autoclean --purge
rm -rf /var/lib/apt/lists/*
sudo timedatectl set-timezone "$TZ"
