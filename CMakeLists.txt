# This is the CMakeLists.txt for power-plug, based on the
# sample CMakeLists.txt for compiling plug for Switchboard
# For more information, look at elementary cmake reference: 
#         http://elementaryos.org/docs/developer-guide/cmake 

cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.6)

set (PLUGNAME "power")

project (${PLUGNAME})

set (DATADIR "${CMAKE_INSTALL_PREFIX}/lib/plugs")
set (PKGDATADIR "${DATADIR}/pantheon/${PLUGNAME}")
set (GETTEXT_PACKAGE "${PLUGNAME}")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configure file
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Files
file (GLOB resources "${CMAKE_CURRENT_SOURCE_DIR}/data/*")

# power-plug

set (PLUG_DEPS "gtk+-3.0;pantheon")

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED ${PLUG_DEPS})

add_definitions (${DEPS_CFLAGS})
link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.12.0" MINIMUM)

include (ValaPrecompile)
vala_precompile (VALA_C
    src/power.vala
PACKAGES
    ${PLUG_DEPS}
OPTIONS

)

# Traslation stuff
add_subdirectory (po)

add_executable (${PLUGNAME} ${VALA_C})

# Installation
install (TARGETS ${PLUGNAME} DESTINATION ${PKGDATADIR})
install (FILES ${resources} DESTINATION ${PKGDATADIR})
