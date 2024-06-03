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

if [ -z ${WRT_THEME} ]; then
  # 默认主题
  WRT_THEME="argon"
fi
if [ -z ${WRT_WIFI} ]; then
  # 默认wifi名
  WRT_WIFI="IAmWifi"
fi

WRT_BRANCH="master"
# github下载地址 很慢
WRT_REPO="https://github.com/coolsnowwolf/lede.git"
# github镜像地址 稍微快一些
# WRT_REPO="https://githubfast.com/coolsnowwolf/lede.git"

####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################
# github actions的默认位置的空间不够 会编译报错
cd /mnt

# 代码克隆
echo "克隆代码 repo: ${WRT_REPO} 分支: ${WRT_BRANCH}"
git clone ${WRT_REPO} -b ${WRT_BRANCH} build
ln -s /mnt/build ${script_dir}/build

cd ${script_dir}/build

# 删掉这个,貌似没用
sed -i "/telephony/d" ./feeds.conf.default

# 替换所有github地址为镜像地址
sed -i "s/${github_addr}/${GITHUB_MIRROR}/g" $(grep ${github_addr} --exclude-dir='.git' -rl .)

# 当前的提交记录ID
WRT_COMMIT_ID="$(git rev-parse HEAD)"

echo "默认参数更改"
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
#修改默认时区
sed -i "s/timezone='.*'/timezone='CST-8'/g" $CFG_FILE
sed -i "/timezone='.*'/a\\\t\t\set system.@system[-1].zonename='$TZ'" $CFG_FILE

LEDE_FILE=$(find ./package/lean/autocore/ -type f -name "index.htm")
#修改默认时间格式
sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S %A")/g' $LEDE_FILE
#添加编译版本标识
sed -i "s@(\(<%=pcdata(ver.luciversion)%>\))@\1  $WRT_REPO-$WRT_DATE@" $LEDE_FILE
#修改默认WIFI名
sed -i "s/ssid=.*/ssid=$WRT_WIFI/g" ./package/kernel/mac80211/files/lib/wifi/mac80211.sh

# wifi 手动启用吧
# sed -i "/wireless.\${name}.disabled/d" package/kernel/mac80211/files/lib/wifi/mac80211.sh || sed -i "/wireless.\${name}.disabled/d" package/network/config/wifi-scripts/files/lib/wifi/mac80211.sh

echo "更新 feeds"
./scripts/feeds update -a
./scripts/feeds install -a

echo "插件处理"

# 移除要替换的包
rm -rf ./feeds/luci/themes/luci-theme-argon
rm -rf ./feeds/luci/applications/luci-app-frp*
rm -rf ./feeds/packages/net/smartdns
rm -rf ./feeds/packages/net/frp
rm -rf ./feeds/packages/multimedia/UnblockNeteaseMusic*
rm -rf ./feeds/luci/applications/luci-app-mosdns
rm -rf ./feeds/packages/net/alist

mkdir -p ./package/custom_plug

# 主题
git clone --depth=1 -b v2.3.1 https://github.com/jerrykuku/luci-theme-argon package/custom_plug/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/custom_plug/luci-app-argon-config

# SmartDNS
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/custom_plug/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/custom_plug/smartdns

# Alist
git clone --depth=1 https://github.com/sbwml/luci-app-alist package/custom_plug/luci-app-alist

# 网易云解锁
git clone --depth=1 https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic package/custom_plug/luci-app-unblockneteasemusic

# 这里不想出现插件覆盖的警告 所以就直接删除指定的
git clone https://${GITHUB_MIRROR}/kiddin9/openwrt-packages.git -b master kiddin9
app_list="luci-app-advancedplus frp luci-app-frpc upx luci-app-fan luci-app-filebrowser \
          ddnsto luci-app-ddnsto"

for item in ${app_list}; do
  if [[ -d "./kiddin9/${item}" ]]; then
    mv ./kiddin9/${item} ./package/custom_plug
  fi
done
rm -rf ./kiddin9

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version}/g" package/lean/default-settings/files/zzz-default-settings

# 修改 Makefile
# 这里是将../../xxx 替换为绝对路径
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

echo "插件处理结束"

echo "更新 feeds"
./scripts/feeds update -a
./scripts/feeds install -a

echo "拷贝配置文件"
cp ${script_dir}/common/.config .config

echo "生成配置文件"
make defconfig
cat .config

echo "下载依赖"
make download -j$(($(nproc) + 1)) V=s
find dl -size -1024c -exec ls -l {} \;
find dl -size -1024c -exec rm -f {} \;

echo "执行编译"
echo -e "$(($(nproc) + 1)) thread compile"
make -j$(($(nproc) + 1)) V=s
