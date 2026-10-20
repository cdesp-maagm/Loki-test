
DTS = "git/arch/${ARCH}/boot/dts"

SRC_URI += "\
    file://loki-common.dtsi;subdir=${DTS} \
    file://loki-modem.dtsi;subdir=${DTS} \
    file://loki-env-sensors.dtsi;subdir=${DTS} \
    file://loki-stub.dtsi;subdir=${DTS} \
    file://loki-microzed.dtsi;subdir=${DTS} \
    file://loki-microzed.cfg \
    file://loki-modem-zedboard.dts;subdir=${DTS} \
    file://loki-modem-microzed.dts;subdir=${DTS} \
    file://loki-modem-redpitaya.dts;subdir=${DTS} \
    file://loki-stub-zedboard.dts;subdir=${DTS} \
    file://loki-stub-microzed.dts;subdir=${DTS} \
    file://loki-stub-redpitaya.dts;subdir=${DTS} \
    file://drivers-leds-Kconfig.patch \
    file://drivers-leds-Makefile.patch \
    file://drivers-leds-led-class.c.patch \
    file://include-dt-bindings-leds-common.h.patch \
    file://led-class-multicolor.h;subdir=git/include/linux \
    file://led-class-multicolor.c;subdir=git/drivers/leds \
    file://leds-lp50xx.c;subdir=git/drivers/leds \
    "

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:${THISDIR}/${PN}/patches:"

PACKAGE_ARCH = "${MACHINE_ARCH}"

KERNEL_DEVICETREE_zedboard-zynq7 += "loki-modem-zedboard.dtb loki-stub-zedboard.dtb"
KERNEL_DEVICETREE_microzed       += "loki-modem-microzed.dtb loki-stub-microzed.dtb"
KERNEL_DEVICETREE_redpitaya      += "loki-modem-redpitaya.dtb loki-stub-redpitaya.dtb"
