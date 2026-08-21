FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Custom LWB5+ device trees to install into the kernel source
LWB_DTS_FILES = "dts/imx8mp-evk-lwb5plus.dts"

SRC_URI += "file://dts/imx8mp-evk-lwb5plus.dts"

# Build the custom dtb for this machine
KERNEL_DEVICETREE:append:imx8mpevk = " freescale/imx8mp-evk-lwb5plus.dtb"

# Summit/Ezurio backports (kernel-module-lwb-if-backports) ships its own
# cfg80211, mac80211 and Bluetooth modules. Its checks.h only errors out when
# these are BUILT INTO the kernel (=y); a module (=m) is fine (CONFIG_X_MODULE,
# not CONFIG_X, is defined, so the #if is false). Keeping CONFIG_CFG80211=m is
# also required so net_device.ieee80211_ptr (guarded by IS_ENABLED(CONFIG_CFG80211))
# stays present for the backports' own cfg80211 to compile.
#
# linux-imx bakes imx_v8_defconfig in via do_copy_defconfig (which overwrites
# configme fragments) and DELTA_KERNEL_DEFCONFIG's merge_config.sh cannot force
# =y symbols to 'not set'. So we patch imx_v8_defconfig itself here.
do_patch:append() {
    if [ -d "${S}/arch/arm64/boot/dts/freescale" ]; then
        for i in ${LWB_DTS_FILES}; do
            if [ -f "${UNPACKDIR}/${i}" ]; then
                bbnote "Installing LWB5+ device tree ${i}"
                install -m 0644 "${UNPACKDIR}/${i}" "${S}/arch/arm64/boot/dts/freescale/"
            fi
        done
    fi
    # Align imx_v8_defconfig with the LWB5+ radio bring-up guidance:
    #   CFG80211   -> module (=m)  : backports WLAN needs ieee80211_ptr present; =m dodges checks.h
    #   MAC80211   -> off          : Summit backports provides its own
    #   WLAN       -> off          : no in-tree wireless LAN drivers
    #   BT         -> off          : Summit backports provides its own BT stack (lwb config)
    #   FW_LOADER_USER_HELPER_FALLBACK -> off
    #   IMX_SDMA   -> module (=m)
    DEF="${S}/arch/arm64/configs/imx_v8_defconfig"
    if [ -f "$DEF" ]; then
        bbnote "LWB5+: aligning imx_v8_defconfig with LWB5+ backports guidance"
        sed -i \
            -e '/^CONFIG_CFG80211=y$/d' \
            -e '/^CONFIG_CFG80211=m$/d' \
            -e '/^# CONFIG_CFG80211 is not set$/d' \
            -e '/^CONFIG_MAC80211=y$/d' \
            -e '/^CONFIG_CFG80211_WEXT=y$/d' \
            -e '/^CONFIG_CFG80211_REQUIRE_SIGNED_REGDB=y$/d' \
            -e '/^CONFIG_CFG80211_USE_KERNEL_REGDB_KEYS=y$/d' \
            -e '/^CONFIG_CFG80211_DEFAULT_PS=y$/d' \
            -e '/^CONFIG_CFG80211_CRDA_SUPPORT=y$/d' \
            -e '/^CONFIG_MAC80211_LEDS=y$/d' \
            -e '/^CONFIG_MAC80211_HAS_RC=y$/d' \
            -e '/^CONFIG_MAC80211_RC_MINSTREL=y$/d' \
            -e '/^CONFIG_MAC80211_RC_DEFAULT_MINSTREL=y$/d' \
            -e '/^CONFIG_MAC80211_RC_DEFAULT=/d' \
            -e '/^CONFIG_WLAN=y$/d' \
            -e '/^CONFIG_BT=y$/d' \
            -e '/^CONFIG_BT=m$/d' \
            -e '/^CONFIG_FW_LOADER_USER_HELPER_FALLBACK=y$/d' \
            -e '/^CONFIG_IMX_SDMA=y$/c\CONFIG_IMX_SDMA=m' \
            "$DEF"
        # Force the symbols to our desired state (append, last match wins in kconfig)
        printf 'CONFIG_CFG80211=m\n' >> "$DEF"
        printf '# CONFIG_MAC80211 is not set\n' >> "$DEF"
        printf '# CONFIG_WLAN is not set\n' >> "$DEF"
        printf '# CONFIG_BT is not set\n' >> "$DEF"
        printf '# CONFIG_FW_LOADER_USER_HELPER_FALLBACK is not set\n' >> "$DEF"
    fi
}
