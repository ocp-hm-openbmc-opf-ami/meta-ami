cmake_minimum_required(VERSION 3.22)
project(nss_radius)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Boost REQUIRED)
include_directories(${Boost_INCLUDE_DIRS})
add_definitions(-DBOOST_ERROR_CODE_HEADER_ONLY)
add_definitions(-DBOOST_SYSTEM_NO_DEPRECATED)
add_definitions(-DBOOST_ALL_NO_LIB)
add_definitions(-DBOOST_NO_RTTI)
add_definitions(-DBOOST_NO_TYPEID)
add_definitions(-DBOOST_ASIO_DISABLE_THREADS)

find_package(PkgConfig REQUIRED)
pkg_check_modules(SYSTEMD libsystemd REQUIRED)

# import sdbusplus
find_package(PkgConfig REQUIRED)
pkg_check_modules(SDBUSPLUSPLUS sdbusplus REQUIRED)
pkg_get_variable(SYSTEMD_SYSTEM_UNIT_DIR systemd systemdsystemunitdir)

#target_link_libraries(${PROJECT_NAME} systemd)
#target_link_libraries(${PROJECT_NAME} boost_coroutine)
#target_link_libraries(nss_pam_radius sdbusplus -lstdc++fs)
#target_link_libraries(${PROJECT_NAME} ${Boost_LIBRARIES})
#link_directories(${EXTERNAL_INSTALL_LOCATION}/lib)

include_directories(
        ${PROJECT_SOURCE_DIR}/include
        ${PROJECT_SOURCE_DIR}/src
)

file(GLOB all_SRCS
        "${PROJECT_SOURCE_DIR}/include/*.h"
        "${PROJECT_SOURCE_DIR}/src/*.c"
        "${PROJECT_SOURCE_DIR}/src/*.cpp"
        )

add_library(${PROJECT_NAME} SHARED ${all_SRCS})
install(TARGETS ${PROJECT_NAME} DESTINATION "${CMAKE_INSTALL_LIBDIR}/${PROJECT_NAME}")

#link_directories(${CMAKE_INSTALL_LIBDIR})
#target_link_libraries(nss_pam-radius ${CMAKE_INSTALL_LIBDIR}/nss-pam-radius)

add_executable(nss_pam_radius src/nss_pam_radius_main.cpp)
install(TARGETS nss_pam_radius DESTINATION ${CMAKE_INSTALL_BINDIR})

#link_directories(${CMAKE_INSTALL_LIBDIR})
target_link_libraries(nss_pam_radius ${PROJECT_NAME})

target_link_libraries(nss_pam_radius systemd)
target_link_libraries(nss_pam_radius boost_coroutine)
target_link_libraries(nss_pam_radius sdbusplus -lstdc++fs)
#target_link_libraries(nss_pam_radius ${Boost_LIBRARIES})
link_directories(${EXTERNAL_INSTALL_LOCATION}/lib)


#target_link_libraries(nss_pam-radius nss-pam-radius)

