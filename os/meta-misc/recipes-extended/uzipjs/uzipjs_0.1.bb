DESCRIPTION = "UZIP.js - Simple ZIPping library for Javascript"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=fd39f1a418d737b39afcffa877ca1a17"

SRC_URI = "git://github.com/photopea/UZIP.js.git;protocol=https"

SRCREV = "a04436a780a909748b886ac10db92f12bc22e1ef"

S = "${WORKDIR}/git"

WWWDIR = "/www/pages"

FILES_${PN} += "${WWWDIR}/*"

do_install() {
    install -d ${D}${WWWDIR}
    install -m 0644 ${S}/*.js ${D}${WWWDIR}
}
