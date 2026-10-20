cmake_minimum_required(VERSION 3.8)
project(libloki-benchmarks LANGUAGES C)

set(THREADS_PREFER_PTHREAD_FLAG ON)
set(THREADS_PTHREAD_ARG "-pthread" CACHE STRING "Result from TRY_RUN" FORCE)
find_package(Threads REQUIRED)

set(CMAKE_C_FLAGS_DEBUG "-g")

add_executable(libloki-benchmarks
    src/libloki-benchmarks-arguments.c
    src/libloki-benchmarks.c
)

target_link_libraries(libloki-benchmarks
    loki
    m
    Threads::Threads
)

install(TARGETS libloki-benchmarks DESTINATION bin)
