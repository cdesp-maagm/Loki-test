
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
    file://${PN}-${PV}/packaging/deb/etc_default_gpsd \
    file://${PN}-${PV}/packaging/deb/etc_init.d_gpsd \
    file://gps0.rules \
    "

# Forcer gpsd à démarrer avant NTPD
INITSCRIPT_PARAMS = "defaults 18"

# Créer un lien symbolique /dev/gps0 vers /dev/ttyPS1.
# /dev étant monté au démarrage par devtmpfs,
# on ne peut pas créer un lien symbolique dans /dev
# à la construction de l'image.
# On utilise udev pour cela.

FILES_${PN} += "${sysconfdir}/udev/rules.d/*"

do_install_append() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 644 ${WORKDIR}/gps0.rules ${D}${sysconfdir}/udev/rules.d
}
