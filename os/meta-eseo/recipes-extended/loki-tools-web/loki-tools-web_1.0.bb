DESCRIPTION = "Loki tools with web interface"
LICENSE = "CLOSED"

DEPENDS        = "python3"
RDEPENDS_${PN} = "uzipjs"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://loki-web-server \
    file://services/__init__.py \
    file://services/config.py \
    file://services/config.tpl.html \
    file://config.js \
    file://config.html \
    file://services/plot.py \
    file://services/plot.tpl.html \
    file://plot.js \
    file://plot.html \
    file://services/files.py \
    file://files.js \
    file://files.html \
    file://services/status.py \
    file://services/startstop.py \
    file://services/dispreset.py \
    file://index.html \
    file://main.css \
    "

WWWDIR = "/www/pages"

inherit python3-dir

FILES_${PN} += "${WWWDIR}/* ${PYTHON_SITEPACKAGES_DIR}/* ${bindir}/*"

do_install() {
    install -d ${D}${bindir}
    install -d ${D}${WWWDIR}
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}/eseo/loki/web

    install -m 0755 ${WORKDIR}/loki-web-server ${D}${bindir}
    install -m 0644 ${WORKDIR}/services/*      ${D}${PYTHON_SITEPACKAGES_DIR}/eseo/loki/web
    install -m 0644 ${WORKDIR}/*.html          ${D}${WWWDIR}
    install -m 0644 ${WORKDIR}/*.js            ${D}${WWWDIR}
    install -m 0644 ${WORKDIR}/*.css           ${D}${WWWDIR}
}
