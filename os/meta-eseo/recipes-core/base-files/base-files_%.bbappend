
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

dirs755_append = " /media/data"

do_install_append() {
    echo "/dev/mmcblk0p2 /media/data auto defaults,sync 0 0" >> ${D}${sysconfdir}/fstab
}
