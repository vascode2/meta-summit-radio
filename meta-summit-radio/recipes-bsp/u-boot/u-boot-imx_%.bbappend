FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Default to booting the Summit LWB5+ device tree (SDIO Wi-Fi + CYW4373A0 BT)
SRC_URI:append:imx8mpevk = " file://imx8mpevk-lwb5plus.cfg"
