DESCRIPTION = "Command-line tools for Loki management"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://loki-modem-config \
    file://loki-modem-record \
    file://loki-env-sensors-record \
    file://loki-record-config \
    file://loki-record \
    file://loki-indicators \
    file://loki-panic \
    file://loki-cal \
    file://defaults.py \
    "

FILES_${PN} += "\
    ${bindir}/* \
    ${libdir}/* \
    "

inherit python3-dir

do_install_prepend() {
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}/eseo/loki
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-modem-config       ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-modem-record       ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-env-sensors-record ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-record-config      ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-record             ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-indicators         ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-panic              ${D}${bindir}
    install -m 0755 ${WORKDIR}/loki-cal                ${D}${bindir}

    install -m 0644 ${WORKDIR}/*.py ${D}${PYTHON_SITEPACKAGES_DIR}/eseo/loki
}
