#!/bin/bash -e
# 编译定制版的openwrt
script_dir=$(
  cd $(dirname $0)
  pwd
)
# 开启扩展
shopt -s extglob

github_addr="github.com"
if [ -z ${GITHUB_MIRROR} ]; then
  # github的镜像地址
  GITHUB_MIRROR="github.com"
fi
if [ -z ${WRT_IP} ]; then
  # 默认IP地址
  WRT_IP="192.168.15.1"
fi

# 当前的稳定分支
wrt_branch="v23.05.3"
# github下载地址 很慢
wrt_repo_url="https://github.com/openwrt/openwrt.git"
# github镜像地址 稍微快一些
# wrt_repo_url="https://githubfast.com/openwrt/openwrt.git"
# 南京大学的镜像速度很快
# wrt_repo_url="https://git.nju.edu.cn/nju/openwrt.git"

####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################
# 代码克隆
echo "克隆代码 repo: ${wrt_repo_url} 分支: ${wrt_branch}"
git clone ${wrt_repo_url} -b ${wrt_branch} build

# 增加仓库
# echo "src-git kiddin9 https://${GITHUB_MIRROR}/kiddin9/openwrt-packages.git;master" >> openwrt/feeds.conf.default
# 删掉这个,貌似没用
sed -i "/telephony/d" build/feeds.conf.default
# openwrt可以使用南京的镜像
# sed -i "s@git.openwrt.org/feed/@git.nju.edu.cn/nju/openwrt-@g" openwrt/feeds.conf.default
# sed -i "s@git.openwrt.org/project/@git.nju.edu.cn/nju/openwrt-@g" openwrt/feeds.conf.default

# 替换所有github地址为镜像地址
sed -i "s/${github_addr}/${GITHUB_MIRROR}/g" $(grep ${github_addr} --exclude-dir='.git' -rl openwrt)

cd build
echo "拷贝配置文件"
cp ${script_dir}/common/.config .config

sed -i "s?targets/%S/packages?targets/%S/\$(LINUX_VERSION)?" include/feeds.mk
sed -i '/	refresh_config();/d' scripts/feeds

echo "拷贝下载脚本"
cp ${script_dir}/common/download.pl ./scripts/download.pl

echo "插件处理"
# 删除重复的 删除旧的 保留新的 保留需要的
git clone https://${GITHUB_MIRROR}/kiddin9/openwrt-packages.git -b master kiddin9
app_list="luci-app-advancedplus luci-app-firewall luci-app-opkg luci-app-upnp luci-app-autoreboot luci-app-wizard \
          luci-base luci-lib-fs coremark curl autocore luci-app-fan luci-app-filebrowser luci-app-alist \
          luci-app-socat frp luci-app-frpc ddns-scripts ddnsto luci-app-ddns luci-app-ddnsto dockerd luci-app-docker \
          luci-app-vlmcsd vlmcsd r8101 r8125 r8126 r8152 r8168 alist upx"
# base-files
mkdir -p ./package/kiddin9
for item in ${app_list}; do
  if [[ -d "./kiddin9/${item}" ]]; then
    mv ./kiddin9/${item} ./package/kiddin9
  fi
done
rm -rf ./kiddin9

echo "插件处理结束"
echo "更新 feeds"
./scripts/feeds update -a
./scripts/feeds install -a

sed -i '/$(curdir)\/compile:/c\$(curdir)/compile: package/opkg/host/compile' package/Makefile
# --force-overwrite 覆盖已经存在的文件
# --force-depends 忽略包的依赖关系并强制安装包
sed -i 's/$(TARGET_DIR)) install/$(TARGET_DIR)) install --force-overwrite --force-depends/' package/Makefile
# 默认包
# luci-app-advancedplus高级设置
# luci-app-firewall 防火墙
# luci-app-opkg 软件管理界面
# luci-app-upnp 通用即插即用UPnP（端口自动转发
# luci-app-autoreboot 自动重启
# luci-app-wizard 设置向导
# luci-app-fan 风扇控制
# luci-app-filebrowser 文件浏览器
sed -i "s/DEFAULT_PACKAGES:=/DEFAULT_PACKAGES:=luci-app-advancedplus luci-app-firewall luci-app-opkg luci-app-upnp luci-app-autoreboot \
luci-app-wizard luci-base luci-compat luci-lib-ipkg luci-lib-fs \
coremark wget-ssl curl autocore htop nano zram-swap kmod-lib-zstd kmod-tcp-bbr bash openssh-sftp-server block-mount resolveip ds-lite swconfig luci-app-fan luci-app-filebrowser /" include/target.mk

sed -i 's/DEFAULT_PACKAGES +=/DEFAULT_PACKAGES += kmod-usb-hid kmod-mmc kmod-sdhci usbutils pciutils lm-sensors-detect kmod-alx kmod-vmxnet3 kmod-igbvf kmod-iavf kmod-bnx2x kmod-pcnet32 kmod-tulip kmod-r8101 kmod-r8125 kmod-8139cp kmod-8139too kmod-i40e kmod-drm-i915 kmod-drm-amdgpu kmod-mlx4-core kmod-mlx5-core fdisk lsblk kmod-phy-broadcom/' target/linux/x86/Makefile

# 貌似这个和dnsmasq不兼容
sed -i "s/procd-ujail//" include/target.mk

sed -i "s/^.*vermagic$/\techo '1' > \$(LINUX_DIR)\/.vermagic/" include/kernel-defaults.mk

# 更改默认ip地址
# sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" package/feeds/kiddin9/base-files/files/bin/config_generate
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" package/base-files/files/bin/config_generate

#sed -i "/call Build\/check-size,\$\$(KERNEL_SIZE)/d" include/image.mk

# 使用lede的video.mk模块覆盖
cp ${script_dir}/common/other_packages/lede_video.mk package/kernel/linux/modules/video.mk
# curl -sfL https://raw.githubusercontent.com/coolsnowwolf/lede/master/package/kernel/linux/modules/video.mk -o package/kernel/linux/modules/video.mk

# -n 不覆盖现有文件
# cp -rn ${script_dir}/common/other_packages/lede_target/* target/
# git_clone_path master https://github.com/coolsnowwolf/lede target/linux/generic/hack-5.15
# git_clone_path master https://github.com/coolsnowwolf/lede target/linux/x86/files target/linux/x86/patches-5.15

# 警告视为错误 先不关闭
# sed -i "s/CONFIG_WERROR=y/CONFIG_WERROR=n/" target/linux/generic/config-5.15

sed -i "s/no-lto,$/no-lto no-mold,$/" include/package.mk

[ -d package/kernel/mt76 ] && {
  mkdir package/kernel/mt76/patches
  cp ${script_dir}/common/other_packages/lede_mt76_patches/0001-mt76-allow-VHT-rate-on-2.4GHz.patch package/kernel/mt76/patches/0001-mt76-allow-VHT-rate-on-2.4GHz.patch
  # curl -sfL https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/package/kernel/mt76/patches/0001-mt76-allow-VHT-rate-on-2.4GHz.patch -o package/kernel/mt76/patches/0001-mt76-allow-VHT-rate-on-2.4GHz.patch
}

# 用master的libpfring替换当前的
rm -rf feeds/packages/libs/libpfring
cp -r ${script_dir}/common/other_packages/openwrt_libpfring feeds/packages/libs/libpfring
# git_clone_path master https://github.com/openwrt/packages libs/libpfring

cp ${script_dir}/common/other_packages/lede_base_files_network/config-5.10 target/linux/x86/64/config-5.15
# curl -sfL https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/x86/64/config-5.15 -o target/linux/x86/64/config-5.15

cp -Rf ${script_dir}/common/other_packages/custom/* .

# rm -rf package/network/utils/xdp-tools package/feeds/kiddin9/fibocom_MHI package/feeds/packages/v4l2loopback

# grep -q 'PKG_RELEASE:=9' package/libs/openssl/Makefile && {
# sh -c "curl -sfL https://github.com/openwrt/openwrt/commit/a48d0bdb77eb93f7fba6e055dace125c72755b6a.patch | patch -d './' -p1 --forward"
# }

sed -i "/wireless.\${name}.disabled/d" package/kernel/mac80211/files/lib/wifi/mac80211.sh || sed -i "/wireless.\${name}.disabled/d" package/network/config/wifi-scripts/files/lib/wifi/mac80211.sh

sed -i 's/Os/O2/g' include/target.mk
sed -i "/mediaurlbase/d" package/feeds/*/luci-theme*/root/etc/uci-defaults/*
sed -i 's/=bbr/=cubic/' package/kernel/linux/files/sysctl-tcp-bbr.conf

# find target/linux/x86 -name "config*" -exec bash -c 'cat kernel.conf >> "{}"' \;
sed -i 's/max_requests 3/max_requests 20/g' package/network/services/uhttpd/files/uhttpd.config
#rm -rf ./feeds/packages/lang/{golang,node}
sed -i "s/tty\(0\|1\)::askfirst/tty\1::respawn/g" target/linux/*/base-files/etc/inittab

date=$(date +%m.%d.%Y)
sed -i -e "/\(# \)\?REVISION:=/c\REVISION:=$date" -e '/VERSION_CODE:=/c\VERSION_CODE:=$(REVISION)' include/version.mk

sed -i \
  -e "s/+\(luci\|luci-ssl\|uhttpd\)\( \|$\)/\2/" \
  -e "s/+nginx\( \|$\)/+nginx-ssl\1/" \
  -e 's/+python\( \|$\)/+python3/' \
  -e 's?../../lang?$(TOPDIR)/feeds/packages/lang?' \
  package/kiddin9/*/Makefile

sed -i 's/256/1024/g' target/linux/x86/image/Makefile

echo '
CONFIG_ACPI=y
CONFIG_X86_ACPI_CPUFREQ=y
CONFIG_NR_CPUS=512
CONFIG_MMC=y
CONFIG_MMC_BLOCK=y
CONFIG_SDIO_UART=y
CONFIG_MMC_TEST=y
CONFIG_MMC_DEBUG=y
CONFIG_MMC_SDHCI=y
CONFIG_MMC_SDHCI_ACPI=y
CONFIG_MMC_SDHCI_PCI=y
CONFIG_DRM_I915=y
' >>./target/linux/x86/config-5.15

sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config

echo "应用补丁"
# 应用补丁
find "${script_dir}/common/patches" -maxdepth 1 -type f -name '*.revert.patch' -print0 | sort -z | xargs -I % -t -0 -n 1 sh -c "cat '%'  | patch -d './' -R -B --merge -p1 -E --forward"
find "${script_dir}/common/patches" -maxdepth 1 -type f -name '*.patch' ! -name '*.revert.patch' ! -name '*.bin.patch' -print0 | sort -z | xargs -I % -t -0 -n 1 sh -c "cat '%'  | patch -d './' -B --merge -p1 -E --forward"
sed -i '$a  \
CONFIG_CPU_FREQ_GOV_POWERSAVE=y \
CONFIG_CPU_FREQ_GOV_USERSPACE=y \
CONFIG_CPU_FREQ_GOV_ONDEMAND=y \
CONFIG_CPU_FREQ_GOV_CONSERVATIVE=y \
CONFIG_CRYPTO_CHACHA20_NEON=y \
CONFIG_CRYPTO_CHACHA20POLY1305=y \
CONFIG_FAT_DEFAULT_IOCHARSET="utf8" \
' $(find target/linux -path "target/linux/*/config-*")

echo "生成配置文件"
make defconfig
cat .config

echo "下载依赖"
make download -j$(($(nproc) + 1)) V=s

echo "执行编译"
echo -e "$(($(nproc) + 1)) thread compile"
make -j$(($(nproc) + 1)) V=s

# (
# if [ -f sdk.tar.xz ]; then
# 	sed -i 's,$(STAGING_DIR_HOST)/bin/upx,upx,' package/feeds/kiddin9/*/Makefile
# 	mkdir sdk
# 	tar -xJf sdk.tar.xz -C sdk
# 	cp -rf sdk/*/staging_dir/* ./staging_dir/
# 	rm -rf sdk.tar.xz sdk
# 	sed -i '/\(tools\|toolchain\)\/Makefile/d' Makefile
# 	if [ -f /usr/bin/python ]; then
# 		ln -sf /usr/bin/python staging_dir/host/bin/python
# 	else
# 		ln -sf /usr/bin/python3 staging_dir/host/bin/python
# 	fi
# 	ln -sf /usr/bin/python3 staging_dir/host/bin/python3
# fi
# ) &
