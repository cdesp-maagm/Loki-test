cmake_minimum_required(VERSION 3.8)
project(libloki LANGUAGES C)

set(THREADS_PREFER_PTHREAD_FLAG ON)
set(THREADS_PTHREAD_ARG "-pthread" CACHE STRING "Result from TRY_RUN" FORCE)
find_package(Threads REQUIRED)

set(CMAKE_C_FLAGS_DEBUG "-g")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -flto -O3")

set(LIB_SRC
    src/libloki-hooks.c
    src/libloki-fifo.c
    src/libloki-modem.c
    src/libloki-env-sensors.c
    src/libloki-ellipse.c
    src/libloki-ellipse-estimator.c
    src/libloki-nlms.c
    src/libloki-rls.c
    src/libloki-kalman.c
    src/libloki-fir.c
    src/libloki-displacement.c
    src/libloki-system.c
    src/libloki-formatter.c
    src/libloki-raw.c
    src/libloki-mseed.c
    src/libloki-recorder.c
    src/libloki-socket-server.c
    src/libloki-consumer.c
)

add_library(loki SHARED ${LIB_SRC})

target_link_libraries(loki
    m
    dl
    mseed
    rt
    Threads::Threads
)

# Donner un numéro de version aux fichiers .so pour créer des liens symboliques
# libloki.so -> libloki.so.N
# Cela évite une erreur avec Yocto.
set_target_properties(loki PROPERTIES SOVERSION 1)

install(TARGETS loki DESTINATION lib)

# ------------------------------------------------------------------------------
# Génération d'un wrapper Python3 avec SWIG
# ------------------------------------------------------------------------------

find_package(SWIG REQUIRED)
include(${SWIG_USE_FILE})

find_package(PythonLibs 3 REQUIRED)
include_directories(${PYTHON_INCLUDE_PATH} src)

swig_add_module(native python src/libloki.i)
swig_link_libraries(native ${PYTHON_LIBRARIES} loki)

install(TARGETS ${SWIG_MODULE_native_REAL_NAME} LIBRARY DESTINATION ${LOKI_SITEPACKAGES_DIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/native.py DESTINATION ${LOKI_SITEPACKAGES_DIR})
