DESCRIPTION = "Prevent accidental shutdown"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://rc \
    file://shutdown \
    file://run.d/30-query-hostname \
    "

FILES_${PN} = "\
    ${sysconfdir}/* \
    ${sbindir}/* \
    "

do_install_append() {
    install -d ${D}${sysconfdir}/molly-guard/run.d
    install -d ${D}${sbindir}
    install -m 0644 ${WORKDIR}/rc       ${D}${sysconfdir}/molly-guard
    install -m 0755 ${WORKDIR}/run.d/*  ${D}${sysconfdir}/molly-guard/run.d
    install -m 0755 ${WORKDIR}/shutdown ${D}${sbindir}/shutdown
    install -m 0755 ${WORKDIR}/shutdown ${D}${sbindir}/reboot
    install -m 0755 ${WORKDIR}/shutdown ${D}${sbindir}/halt
    install -m 0755 ${WORKDIR}/shutdown ${D}${sbindir}/poweroff
}
