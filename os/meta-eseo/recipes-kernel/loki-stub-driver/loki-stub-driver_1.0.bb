SUMMARY = "Linux kernel module for the AXI stream transceiver stub"
LICENSE = "CLOSED"

inherit module

SRC_URI = "file://Makefile \
           file://${PN}.c \
          "

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

S = "${WORKDIR}"
