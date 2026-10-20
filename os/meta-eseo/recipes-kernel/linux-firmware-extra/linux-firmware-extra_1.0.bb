DESCRIPTION = "Extra firmware files for use with Linux kernel"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "\
    file://rtl8821c_fw.bin \
    file://rtl8821c_config.bin \
    "

FILES_${PN} += "${nonarch_base_libdir}/firmware/*"

do_install() {
    install -d  ${D}${nonarch_base_libdir}/firmware/rtl_bt
    install -m 0644 ${WORKDIR}/rtl8821c* ${D}${nonarch_base_libdir}/firmware/rtl_bt
}
