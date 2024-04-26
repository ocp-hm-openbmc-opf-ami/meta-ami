cmake_minimum_required (VERSION 3.5 FATAL_ERROR)

project (libmctp-intel-test)

set(CMAKE_C_FLAGS
    "${CMAKE_C_FLAGS} \
    -Wall \
    -Werror \
    -Wextra \
    -Wunused \
    -Wnull-dereference \
    -Wpointer-to-int-cast \
    -Wformat=2 \
")

# Remove if code fixes
set(CMAKE_C_FLAGS
    "${CMAKE_C_FLAGS} \
    -Wno-unused-parameter \
    -Wno-sign-compare \
    -Wno-type-limits \
")

add_executable (mctp-astpcie-test mctp-astpcie-test.c mctp-test-utils.c)
target_link_libraries (mctp-astpcie-test mctp_intel)
add_executable (mctp-smbus-test mctp-smbus-test.c mctp-test-utils.c)
target_link_libraries (mctp-smbus-test mctp_intel)

install (TARGETS mctp-astpcie-test mctp-smbus-test DESTINATION bin)
