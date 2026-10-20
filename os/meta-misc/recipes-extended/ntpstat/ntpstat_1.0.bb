DESCRIPTION = "Show network time protocol (ntp) status"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://gpl-2.0.txt;md5=b234ee4d69f5fce4486a80fdaf4a4263"

RDEPENDS_${PN} = "ntp"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://CMakeLists.txt \
    file://gpl-2.0.txt \
    file://src/ntpstat.c \
"

S = "${WORKDIR}"

inherit cmake
