# SPDX-License-Identifier: GPL-2.0-only
#
# Vendored from ImmortalWrt luci @ 5fc1fac5 (applications/luci-app-adguardhome),
# attribution retained. Deviation from upstream: the "+adguardhome" binary
# dependency (and the LUCI_EXTRA_DEPENDS version clamp) is dropped - the
# image seed names the `adguardhome` binary explicitly (CONFIG_PACKAGE_adguardhome),
# so it does not ride on this app's dependency; this app just manages the service.

include $(TOPDIR)/rules.mk

LUCI_NAME:=luci-app-adguardhome
LUCI_MAINTAINER:=George Sapkin <george@sapk.in>
PKG_LICENSE:=GPL-2.0-only

LUCI_TITLE:=LuCI support for AdGuard Home
LUCI_DEPENDS:=+luci-base
LUCI_PKGARCH:=all

# Bridging the LuCI app to the service: the stock init never reads
# `adguardhome.<x>.enabled`, so the app's Enable checkbox starts/stops nothing.
# The patch logic lives in a shell script shipped by this package,
# root/usr/libexec/cw-adguard-enable-bridge, shared with the first-boot
# files/etc/uci-defaults/97-cw-adguard-enable-bridge. The script patches via a
# temp file + verify + mv and never truncates the live init. Skipped during the image build (IPKG_INSTROOT): there it would act
# on the build host's /etc.

define Package/$(LUCI_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
if ! /usr/libexec/cw-adguard-enable-bridge; then
	echo "luci-app-adguardhome: Enable-checkbox bridge not applied (logread -e cw-adguard)" >&2
fi
exit 0
endef

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
