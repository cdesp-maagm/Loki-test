cmake_minimum_required(VERSION 3.8)
project(ntpstat)

add_executable(ntpstat src/ntpstat.c)

install(TARGETS ntpstat DESTINATION bin)
