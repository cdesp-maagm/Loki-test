
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# The official logrotate recipe installs a daily cron task automatically.

SRC_URI += "\
    file://00-loki-defaults.conf \
    file://50-loki-logs.conf \
    "

FILES_${PN} += "${sysconfdir}/logrotate.d/*"

do_install_append() {
    install -m 0644 ${WORKDIR}/00-loki-defaults.conf ${D}${sysconfdir}/logrotate.d/
    install -m 0644 ${WORKDIR}/50-loki-logs.conf ${D}${sysconfdir}/logrotate.d/
}
