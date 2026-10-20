DESCRIPTION = "Loki startup scripts"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://loki-macaddr.sh \
    file://loki-ntpdate.sh \
    file://loki-fix-filesystem.sh \
    file://loki-modem-config.sh \
    file://loki-indicators.sh \
    file://loki-record.sh \
    file://loki-env-sensors-record.sh \
    file://loki-web-server.sh \
    file://ringserver.sh \
    file://ringserver.conf \
    file://loki-daemon-wrapper.sh \
    "

inherit update-rc.d

INITSCRIPT_PACKAGES = "\
    ${PN}-macaddr \
    ${PN}-ntpdate \
    ${PN}-fix-filesystem \
    ${PN}-modem-config \
    ${PN}-indicators \
    ${PN}-record \
    ${PN}-env-sensors-record \
    ${PN}-web-server \
    ${PN}-ringserver \
    "

PACKAGES =+ "${INITSCRIPT_PACKAGES}"

DAEMON_WRAPPER = "${sysconfdir}/init.d/loki-daemon-wrapper.sh"

# loki-fix-filesystem doit s'exécuter en tout premier, avant la connexion au réseau.
RDEPENDS_${PN}-fix-filesystem              = "loki-users"
FILES_${PN}-fix-filesystem                 = "${sysconfdir}/init.d/loki-fix-filesystem.sh"
INITSCRIPT_NAME_${PN}-fix-filesystem       = "loki-fix-filesystem.sh"
INITSCRIPT_PARAMS_${PN}-fix-filesystem     = "defaults 0"

RDEPENDS_${PN}-indicators                  = "loki-users"
FILES_${PN}-indicators                     = "${sysconfdir}/init.d/loki-indicators.sh ${DAEMON_WRAPPER}"
INITSCRIPT_NAME_${PN}-indicators           = "loki-indicators.sh"
INITSCRIPT_PARAMS_${PN}-indicators         = "defaults 10"

# loki-ntpdate doit s'exécuter après connexion au réseau et avant ntpd.
RDEPENDS_${PN}-ntpdate                     = "ntp"
FILES_${PN}-ntpdate                        = "${sysconfdir}/init.d/loki-ntpdate.sh"
INITSCRIPT_NAME_${PN}-ntpdate              = "loki-ntpdate.sh"
INITSCRIPT_PARAMS_${PN}-ntpdate            = "defaults 19"

RDEPENDS_${PN}-macaddr                     = "coreutils"
FILES_${PN}-macaddr                        = "${sysconfdir}/init.d/loki-macaddr.sh"
INITSCRIPT_NAME_${PN}-macaddr              = "loki-macaddr.sh"
INITSCRIPT_PARAMS_${PN}-macaddr            = "defaults 70"

RDEPENDS_${PN}-modem-config                = "loki-tools"
FILES_${PN}-modem-config                   = "${sysconfdir}/init.d/loki-modem-config.sh"
INITSCRIPT_NAME_${PN}-modem-config         = "loki-modem-config.sh"
INITSCRIPT_PARAMS_${PN}-modem-config       = "defaults 91"

RDEPENDS_${PN}-ringserver                  = "ringserver"
FILES_${PN}-ringserver                     = "${sysconfdir}/init.d/ringserver.sh ${sysconfdir}/ringserver.conf ${DAEMON_WRAPPER}"
INITSCRIPT_NAME_${PN}-ringserver           = "ringserver.sh"
INITSCRIPT_PARAMS_${PN}-ringserver         = "defaults 92"

RDEPENDS_${PN}-record                      = "loki-tools"
FILES_${PN}-record                         = "${sysconfdir}/init.d/loki-record.sh ${DAEMON_WRAPPER}"
INITSCRIPT_NAME_${PN}-record               = "loki-record.sh"
INITSCRIPT_PARAMS_${PN}-record             = "defaults 93"

RDEPENDS_${PN}-env-sensors-record          = "loki-tools"
FILES_${PN}-env-sensors-record             = "${sysconfdir}/init.d/loki-env-sensors-record.sh ${DAEMON_WRAPPER}"
INITSCRIPT_NAME_${PN}-env-sensors-record   = "loki-env-sensors-record.sh"
INITSCRIPT_PARAMS_${PN}-env-sensors-record = "defaults 93"

RDEPENDS_${PN}-web-server                  = "loki-tools-web"
FILES_${PN}-web-server                     = "${sysconfdir}/init.d/loki-web-server.sh ${DAEMON_WRAPPER}"
INITSCRIPT_NAME_${PN}-web-server           = "loki-web-server.sh"
INITSCRIPT_PARAMS_${PN}-web-server         = "defaults 94"

do_install_append() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/*.sh ${D}${sysconfdir}/init.d/
    install -m 0644 ${WORKDIR}/*.conf ${D}${sysconfdir}/
}
