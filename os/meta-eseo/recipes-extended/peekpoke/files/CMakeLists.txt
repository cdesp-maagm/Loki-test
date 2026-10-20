cmake_minimum_required(VERSION 3.8)
project(peekpoke)

add_executable(peek src/peek.c)
add_executable(poke src/poke.c)

install(TARGETS peek poke DESTINATION bin)
