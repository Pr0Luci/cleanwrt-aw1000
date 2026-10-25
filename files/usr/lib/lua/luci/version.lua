-- CleanWRT overlay: replaces the luci-base-stamped version.lua.
-- The pinned luci feed is a detached-HEAD checkout, so the build stamps git
-- describe noise ("LuCI (HEAD detached at ...) branch ...") into luciname /
-- luciversion, which leaks onto user-facing pages. We ship clean static
-- labels instead; the DISTRIB_* handling below stays stock and runs at
-- runtime off /etc/openwrt_release, so the firmware version stays dynamic.
-- Re-verify against the fresh luci-base template on any luci feed pin bump.

local pcall, dofile, _G = pcall, dofile, _G

module "luci.version"

if pcall(dofile, "/etc/openwrt_release") and _G.DISTRIB_DESCRIPTION then
	distname    = ""
	distversion = _G.DISTRIB_DESCRIPTION
else
	distname    = "OpenWrt"
	distversion = "Development Snapshot"
end

luciname    = "LuCI"
luciversion = "25.12.5"
