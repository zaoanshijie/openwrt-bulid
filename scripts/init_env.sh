#!/bin/bash

if [[ $WRT_URL == *"lede"* ]]; then
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

elif [[ $WRT_URL == *"immortalwrt"* ]]; then
  echo "init immortalwrt build env"
  sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
  sudo -E apt-get update -y
  sudo bash -c 'bash <(curl -s -L https://build-scripts.immortalwrt.eu.org/init_build_environment.sh)'
  sudo -E apt-get install libfuse-dev -y

elif [[ $WRT_URL == *"openwrt"* ]]; then
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

fi

sudo apt-get clean
sudo apt-get autoclean --purge
rm -rf /var/lib/apt/lists/*
sudo timedatectl set-timezone "$TZ"
