DESCRIPTION = "Remote data synchronization scripts"
LICENSE = "CLOSED"

RDEPENDS_${PN} = "cronie"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://loki-sync \
    file://loki-status \
    file://loki-clean \
    file://dbclient-noask \
    "

FILES_${PN} += "${bindir}/*"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-sync      ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-status    ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-clean     ${D}${bindir}
    install -m 0755 ${WORKDIR}/dbclient-noask ${D}${bindir}

    install -d ${D}${sysconfdir}/cron.hourly
    ln -s -r ${D}${bindir}/loki-sync   ${D}${sysconfdir}/cron.hourly
    ln -s -r ${D}${bindir}/loki-status ${D}${sysconfdir}/cron.hourly

    install -d ${D}${sysconfdir}/cron.daily
    ln -s -r ${D}${bindir}/loki-clean ${D}${sysconfdir}/cron.daily
}
