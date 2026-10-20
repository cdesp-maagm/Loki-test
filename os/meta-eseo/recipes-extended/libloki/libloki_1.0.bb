DESCRIPTION = "User mode library for the loki-modem device"
LICENSE = "CLOSED"

DEPENDS = "\
    swig-native \
    python3 \
    loki-device-drivers \
    libmseed \
    "

FILESEXTRAPATHS_prepend = "${THISDIR}/files:"

SRC_URI = "\
    file://CMakeLists.txt \
    file://src/libloki.h \
    file://src/libloki-common.h \
    file://src/libloki-hooks.h \
    file://src/libloki-hooks.c \
    file://src/libloki-class.h \
    file://src/libloki-neon.h \
    file://src/libloki-fifo.h \
    file://src/libloki-fifo.c \
    file://src/libloki-fifo.i \
    file://src/libloki-time.h \
    file://src/libloki-packet.h \
    file://src/libloki-packet.i \
    file://src/libloki-modem.h \
    file://src/libloki-modem.c \
    file://src/libloki-modem.i \
    file://src/libloki-env-sensors.h \
    file://src/libloki-env-sensors.c \
    file://src/libloki-env-sensors.i \
    file://src/libloki-ellipse.h \
    file://src/libloki-ellipse.c \
    file://src/libloki-nlms.h \
    file://src/libloki-nlms.c \
    file://src/libloki-rls.h \
    file://src/libloki-rls.c \
    file://src/libloki-kalman.h \
    file://src/libloki-kalman.c \
    file://src/libloki-fir.h \
    file://src/libloki-fir.c \
    file://src/libloki-ellipse-estimator.h \
    file://src/libloki-ellipse-estimator.c \
    file://src/libloki-displacement.h \
    file://src/libloki-displacement.c \
    file://src/libloki-system-defaults.h \
    file://src/libloki-system.h \
    file://src/libloki-system.c \
    file://src/libloki-system.i \
    file://src/libloki-formatter.h \
    file://src/libloki-formatter.c \
    file://src/libloki-raw.h \
    file://src/libloki-raw.c \
    file://src/libloki-mseed.h \
    file://src/libloki-mseed.c \
    file://src/libloki-recorder.h \
    file://src/libloki-recorder.c \
    file://src/libloki-recorder.i \
    file://src/libloki-socket-server.h \
    file://src/libloki-socket-server.c \
    file://src/libloki-socket-server.i \
    file://src/libloki-consumer.h \
    file://src/libloki-consumer.c \
    file://src/libloki-consumer.i \
    file://src/libloki.i \
    file://src/util.py \
    "

FILES_${PN} += "${libdir}/*"

S = "${WORKDIR}"

inherit python3-dir

EXTRA_OECMAKE = "-DCMAKE_BUILD_TYPE=Debug -DLOKI_SITEPACKAGES_DIR=lib/${PYTHON_DIR}/site-packages/eseo/loki"

inherit cmake

do_install_prepend() {
    install -d ${D}${includedir}
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}/eseo/loki
}

do_install_append() {
    install -m 0644 ${S}/src/libloki*.h ${D}${includedir}
    install -m 0644 ${S}/src/*.py ${D}${PYTHON_SITEPACKAGES_DIR}/eseo/loki
}
