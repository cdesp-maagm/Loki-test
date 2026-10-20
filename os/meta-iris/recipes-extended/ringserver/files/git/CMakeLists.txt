
cmake_minimum_required(VERSION 3.8)
project(ringserver LANGUAGES C)

set(THREADS_PREFER_PTHREAD_FLAG ON)
set(THREADS_PTHREAD_ARG "-pthread" CACHE STRING "Result from TRY_RUN" FORCE)
find_package(Threads REQUIRED)

add_executable(ringserver
	src/stack.c src/rbtree.c src/logging.c src/clients.c src/slclient.c src/dlclient.c
	src/http.c src/dsarchive.c src/mseedscan.c src/generic.c src/ring.c src/ringserver.c
)

target_link_libraries(ringserver
    mseed
    mxml
	pcre
    Threads::Threads
)

target_compile_definitions(ringserver
	PUBLIC _REENTRANT
	PUBLIC _POSIX_PTHREAD_SEMANTICS
)

install(TARGETS ringserver DESTINATION bin)
