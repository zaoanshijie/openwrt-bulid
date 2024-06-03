#!/bin/bash

cd "$GITHUB_WORKSPACE/build"

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

if [[ $WRT_URL == *"lede"* ]]; then
  echo "change lede setting"
  LEDE_FILE=$(find ./package/lean/autocore/ -type f -name "index.htm")
  #修改默认时间格式
  sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S %A")/g' $LEDE_FILE
  #添加编译日期标识
  sed -i "s/(\(<%=pcdata(ver.luciversion)%>\))/\1 \/ $WRT_REPO-$WRT_DATE/" $LEDE_FILE
  #修改默认WIFI名
  sed -i "s/ssid=.*/ssid=$WRT_WIFI/g" ./package/kernel/mac80211/files/lib/wifi/mac80211.sh
elif [[ $WRT_URL == *"immortalwrt"* ]]; then
  echo "change immortalwrt setting"
  #添加编译日期标识
  VER_FILE=$(find ./feeds/luci/modules/ -type f -name "10_system.js")
  awk -v wrt_repo="$WRT_REPO" -v wrt_date="$WRT_DATE" '{ gsub(/(\(luciversion \|\| \047\047\))/, "& + (\047 / "wrt_repo"-"wrt_date"\047)") } 1' $VER_FILE >temp.js && mv -f temp.js $VER_FILE
  #修改默认WIFI名
  sed -i "s/ssid=.*/ssid=$WRT_WIFI/g" ./package/network/config/wifi-scripts/files/lib/wifi/mac80211.sh
elif [[ $WRT_URL == *"openwrt"* ]]; then
  echo "change openwrt setting"

  # rm -rf feeds/packages/net/mosdns
  # rm -rf feeds/packages/net/msd_lite
  #
  # rm -rf feeds/luci/themes/luci-theme-netgear
  # rm -rf feeds/luci/applications/luci-app-mosdns
  # rm -rf feeds/luci/applications/luci-app-netdata
  # rm -rf feeds/luci/applications/luci-app-serverchan

fi

# 移除要替换的包
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/packages/net/smartdns
# 主题
git clone --depth=1 -b v2.3.1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config luci/luci-app-argon-config

# SmartDNS
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# Alist
git clone --depth=1 https://github.com/sbwml/luci-app-alist package/luci-app-alist

# DDNS.to
git_sparse_clone main https://github.com/linkease/nas-packages-luci luci/luci-app-ddnsto
git_sparse_clone master https://github.com/linkease/nas-packages network/services/ddnsto

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings

# 修改 Makefile
# 这里是将../../xxx 替换为绝对路径
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}
