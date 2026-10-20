DESCRIPTION = "Benchmarks for libloki signal processing functions"
LICENSE = "CLOSED"

DEPENDS = "libloki"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://CMakeLists.txt \
    file://src/libloki-benchmarks-arguments.h \
    file://src/libloki-benchmarks-arguments.c \
    file://src/libloki-benchmarks.h \
    file://src/libloki-benchmarks.c \
    "

S = "${WORKDIR}"

EXTRA_OECMAKE = "-DCMAKE_BUILD_TYPE=Debug"

inherit cmake
