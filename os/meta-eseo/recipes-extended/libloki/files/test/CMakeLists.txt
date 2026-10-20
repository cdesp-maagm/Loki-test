
cmake_minimum_required(VERSION 3.8)
project(libloki-test LANGUAGES C)

set(CMAKE_C_FLAGS_DEBUG "-g")

set(SRC
    ../src/libloki-ellipse.c
    ../src/libloki-nlms.c
    ../src/libloki-rls.c
    ../src/libloki-fir.c
    libloki-test.c
)

add_executable(libloki-test ${SRC})

target_include_directories(libloki-test PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../src)

target_link_libraries(libloki-test m cmocka)
