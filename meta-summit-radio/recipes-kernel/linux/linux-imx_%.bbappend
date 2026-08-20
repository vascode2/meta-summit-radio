FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Custom LWB5+ device trees to install into the kernel source
LWB_DTS_FILES = "dts/imx8mp-evk-lwb5plus.dts"

SRC_URI += "file://dts/imx8mp-evk-lwb5plus.dts"

# Build the custom dtb for this machine
KERNEL_DEVICETREE:append:imx8mpevk = " freescale/imx8mp-evk-lwb5plus.dtb"

# Summit/Ezurio backports (kernel-module-lwb-if-backports) ships its own
# cfg80211, mac80211 and Bluetooth modules. Its checks.h errors out if these
# are built into the kernel (=y). linux-imx bakes imx_v8_defconfig in via
# do_copy_defconfig (which overwrites configme fragments), and
# DELTA_KERNEL_DEFCONFIG's merge_config.sh cannot turn =y symbols off
# (it only appends duplicate "is not set" lines). So we patch the defconfig
# itself here so do_copy_defconfig picks it up.
do_patch:append() {
    if [ -d "${S}/arch/arm64/boot/dts/freescale" ]; then
        for i in ${LWB_DTS_FILES}; do
            if [ -f "${UNPACKDIR}/${i}" ]; then
                bbnote "Installing LWB5+ device tree ${i}"
                install -m 0644 "${UNPACKDIR}/${i}" "${S}/arch/arm64/boot/dts/freescale/"
            fi
        done
    fi
    # Disable cfg80211/mac80211/BT so Summit backports can provide them
    DEF="${S}/arch/arm64/configs/imx_v8_defconfig"
    if [ -f "$DEF" ]; then
        bbnote "LWB5+: disabling in-kernel cfg80211/mac80211/BT in imx_v8_defconfig"
        sed -i \
            -e '/^CONFIG_CFG80211=y$/c\# CONFIG_CFG80211 is not set' \
            -e '/^CONFIG_MAC80211=y$/c\# CONFIG_MAC80211 is not set' \
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
            "$DEF"
        if ! grep -q '^# CONFIG_BT is not set$' "$DEF"; then
            printf '# CONFIG_BT is not set\n' >> "$DEF"
        fi
    fi
}
