
do_install_append() {
    ln -s /media/data/config/openvpn/loki1.conf ${D}${sysconfdir}/openvpn
    ln -s /media/data/config/openvpn/loki2.conf ${D}${sysconfdir}/openvpn
    ln -s /media/data/config/openvpn/loki3.conf ${D}${sysconfdir}/openvpn
}
