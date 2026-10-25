// CleanWRT overlay: replaces the luci-base-stamped version.uc with
// clean static labels - the pinned feed's stamped git describe ("LuCI (HEAD
// detached at ...) branch ...") is developer noise on user-facing pages
// (page footer, login footer, `ubus call luci getVersion`). Twin overlay:
// files/usr/lib/lua/luci/version.lua. Re-verify on any luci feed pin bump.
export const revision = '25.12.5', branch = 'LuCI';
