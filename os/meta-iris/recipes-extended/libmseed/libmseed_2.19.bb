DESCRIPTION = "libmseed - The miniSEED data format library"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=4455a5d53e02594d765fc9c54a787a50"

SRC_URI = "git://github.com/iris-edu/libmseed.git;branch=2.x;protocol=https"

# Version 2.19.6 from branch 2.x
SRCREV = "c0d4d2b4392ffc529c5a1747d25c1f88d7a7d351"

S = "${WORKDIR}/git"

do_compile() {
    oe_runmake shared
}

do_install() {
    oe_runmake install DESTDIR=${D} PREFIX=${prefix}
}
