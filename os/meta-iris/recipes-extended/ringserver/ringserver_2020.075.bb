DESCRIPTION = "ringserver - Generic packet ring buffer with network interfaces"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS = "pcre libmseed libmxml"

SRC_URI = "\
    git://github.com/iris-edu/ringserver.git;branch=main;protocol=https \
    file://git/CMakeLists.txt \
    "

#
# Patch temporarily disabled
# file://557e0d7.patch \
#

# Version 2020.075
SRCREV = "5739caf9ab6f4446556f613f7f9f6f91564f8209"

S = "${WORKDIR}/git"

inherit cmake
