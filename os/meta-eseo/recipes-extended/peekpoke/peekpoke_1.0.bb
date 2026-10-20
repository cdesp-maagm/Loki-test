DESCRIPTION = "peek poke"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://CMakeLists.txt \
    file://src/peek.c \
    file://src/poke.c \
"

S = "${WORKDIR}"

inherit cmake
