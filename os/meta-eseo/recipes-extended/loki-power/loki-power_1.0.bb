DESCRIPTION = "Loki power management"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://power-switch.rules \
    "

FILES_${PN} = "${sysconfdir}/*"

do_install_append() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/*.rules ${D}${sysconfdir}/udev/rules.d
}
