DESCRIPTION = "Sterling LWB5+ SDIO/UART M.2 (diversity antenna) sample image"
LICENSE = "MIT"

inherit core-image

export IMAGE_BASENAME = "${PN}"

# Ensure our custom LWB5+ device tree is copied to the FAT boot partition.
# U-Boot's CONFIG_DEFAULT_FDT_FILE loads 'imx8mp-evk-lwb5plus.dtb'; without this
# entry it is built but never placed on the boot partition.
IMAGE_BOOT_FILES:append = " imx8mp-evk-lwb5plus.dtb"

IMAGE_FEATURES += "\
	ssh-server-dropbear \
	splash \
	"

IMAGE_FEATURES:remove = "\
	tools-profile \
	tools-debug \
	tools-testapps \
	"

IMAGE_INSTALL += "\
	iproute2 \
	rng-tools \
	ca-certificates \
	tzdata \
	htop \
	ethtool \
	iperf3 \
	tcpdump \
	iw \
	kernel-module-lwb-if-backports \
	lwb5plus-sdio-div-firmware \
	summit-supplicant \
	summit-networkmanager \
	summit-networkmanager-nmcli \
	libedit \
	"
