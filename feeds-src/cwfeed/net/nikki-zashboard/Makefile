# SPDX-License-Identifier: GPL-2.0-only
#
# nikki-zashboard - the Zashboard web dashboard, preinstalled for Nikki (mihomo).
#
# Zashboard (https://github.com/Zephyruso/zashboard, MIT, (c) 2024 Zephyruso) is a
# static web app that talks to mihomo's external-controller API: proxies, groups,
# latency tests, rules, connections, logs and the active profile. This package
# ships its release build unmodified, so the dashboard works on first start with no
# download. mihomo downloads `external-ui-url` only when the `external-ui` folder is
# missing or empty, and Nikki's "Update Dashboard" button still pulls the newest
# release over this copy (into the overlay).
#
# The "no-fonts" build uses the system fonts: about 5 MiB unpacked, about 1.5 MiB in
# squashfs, against about 9.6 MiB for the build that bundles every font.
# The MIT licence text is installed with it (files/LICENSE, from the same tag).

include $(TOPDIR)/rules.mk

PKG_NAME:=nikki-zashboard
PKG_VERSION:=3.30.0
PKG_RELEASE:=1

PKG_SOURCE:=zashboard-v$(PKG_VERSION)-dist-no-fonts.zip
PKG_SOURCE_URL:=https://github.com/Zephyruso/zashboard/releases/download/v$(PKG_VERSION)/dist-no-fonts.zip?
PKG_HASH:=ec794e7c4daf4c839ecbc0a1292fdaf7bc7a6e3e4a4ce284db2b32379145c278

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/nikki-zashboard
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Zashboard web dashboard for Nikki (mihomo)
  URL:=https://github.com/Zephyruso/zashboard
  DEPENDS:=+nikki
  PKGARCH:=all
endef

define Package/nikki-zashboard/description
  Zashboard, a lightweight dashboard for mihomo, preinstalled in Nikki's
  external-ui folder (/etc/nikki/run/ui) so it opens without a download.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	unzip -q -o $(DL_DIR)/$(PKG_SOURCE) -d $(PKG_BUILD_DIR)
	$(CP) ./files/LICENSE $(PKG_BUILD_DIR)/LICENSE
endef

define Build/Compile
endef

define Package/nikki-zashboard/install
	$(INSTALL_DIR) $(1)/etc/nikki/run/ui
	$(CP) $(PKG_BUILD_DIR)/dist/. $(1)/etc/nikki/run/ui/
	$(INSTALL_DIR) $(1)/usr/share/licenses/zashboard
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/LICENSE $(1)/usr/share/licenses/zashboard/LICENSE
endef

$(eval $(call BuildPackage,nikki-zashboard))
