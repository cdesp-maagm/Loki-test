
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
    file://zynq_zed_defconfig.patch \
    file://zynq_microzed_defconfig.patch \
    "
