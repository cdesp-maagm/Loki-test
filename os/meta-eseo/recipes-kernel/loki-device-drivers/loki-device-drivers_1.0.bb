SUMMARY = "Linux kernel module for Loki, common module"
LICENSE = "CLOSED"

inherit module

SRC_URI = "\
    file://Makefile \
    file://loki-device/Makefile \
    file://loki-device/loki-device.h \
    file://loki-device/loki-device-regs.h \
    file://loki-device/loki-device-regs.c \
    file://loki-device/loki-device-ioctl.h \
    file://loki-device/loki-device-ioctl.c \
    file://loki-device/loki-device-sysfs.h \
    file://loki-device/loki-device-sysfs.c \
    file://loki-device/loki-device-dma.h \
    file://loki-device/loki-device-dma.c \
    file://loki-device/loki-device-module.c \
    file://loki-env-sensors/Makefile \
    file://loki-env-sensors/loki-env-sensors-regs.h \
    file://loki-env-sensors/loki-env-sensors-sysfs.h \
    file://loki-env-sensors/loki-env-sensors-sysfs.c \
    file://loki-env-sensors/loki-env-sensors-module.c \
    file://loki-modem/Makefile \
    file://loki-modem/loki-modem-regs.h \
    file://loki-modem/loki-modem-sysfs.h \
    file://loki-modem/loki-modem-sysfs.c \
    file://loki-modem/loki-modem-module.c \
    "

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

S = "${WORKDIR}"

do_install_append() {
    install -d ${D}${includedir}
    install -m 0644 ${S}/loki-device/loki-device-ioctl.h          ${D}${includedir}
    install -m 0644 ${S}/loki-modem/loki-modem-regs.h             ${D}${includedir}
    install -m 0644 ${S}/loki-env-sensors/loki-env-sensors-regs.h ${D}${includedir}
}
