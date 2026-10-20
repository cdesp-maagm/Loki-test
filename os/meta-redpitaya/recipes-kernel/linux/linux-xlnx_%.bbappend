SRC_URI += "\
    file://zynq-redpitaya.dts;subdir=git/arch/${ARCH}/boot/dts \
    file://zynq-redpitaya.cfg \
"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

PACKAGE_ARCH = "${MACHINE_ARCH}"
