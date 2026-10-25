# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026 Pr0Luci
#
# luci-app-syncthing - the on/off switch for Syncthing.
# Syncthing (official packages feed) has no LuCI app. Original code:
# one view that edits /etc/config/syncthing; the init reloads on that change.

include $(TOPDIR)/rules.mk

LUCI_NAME:=luci-app-syncthing
LUCI_MAINTAINER:=Pr0Luci
PKG_LICENSE:=GPL-2.0-only

LUCI_TITLE:=LuCI support for Syncthing
LUCI_DEPENDS:=+luci-base +syncthing
LUCI_PKGARCH:=all

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
