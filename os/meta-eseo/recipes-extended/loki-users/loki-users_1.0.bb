DESCRIPTION = "Loki user creation"
LICENSE = "CLOSED"
RDEPENDS_${PN} = "sudo"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://loki-sudoers \
    file://loki.rules \
    file://loki-passwd.sh \
    "

inherit useradd

USERADD_PACKAGES = "${PN}"

# Create users:
# * loki:      system user, no home directory
# * loki-user: normal user, in group loki, home in /home/loki-user (linked to /media/data/home), password "changeme"
USERADD_PARAM_${PN} = "--system loki;--uid 1200 --groups loki --home-dir /home/loki-user --no-create-home --password '\$1\$q8TP9gLt\$bRVSJt.l.92UwXsH0oB2K1' loki-user"

FILES_${PN} = "${base_prefix}/home/* ${sysconfdir}/* ${bindir}/*"

do_install () {
    install -d ${D}${base_prefix}/home
    ln -s /media/data/home ${D}${base_prefix}/home/loki-user

    install -d ${D}${sysconfdir}/sudoers.d
    install -m 440 ${WORKDIR}/loki-sudoers ${D}${sysconfdir}/sudoers.d

    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 644 ${WORKDIR}/loki.rules ${D}${sysconfdir}/udev/rules.d

    install -d ${D}${bindir}
    install -m 755 ${WORKDIR}/*.sh ${D}${bindir}
}
