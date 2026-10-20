DESCRIPTION="Realtek RTL8811CU/RTL8821CU USB Wi-Fi adapter driver for Linux"
LICENSE="GPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS="bc-native"

SRC_URI = "\
    git://github.com/brektrou/rtl8821CU.git;protocol=https \
    file://git/Makefile.patch \
    "

SRCREV = "f1bc7e86c4a1c67bee04c361dd978683869d2347"

S = "${WORKDIR}/git"

inherit module
