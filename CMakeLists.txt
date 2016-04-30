# This a sample CMakeLists.txt for compiling plug for Switchboard
# http://elementaryos.org/docs/developer-guide/cmake 

cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.6)

# Set the Properties of your Plug

# Set the Category of the Plug, one of:
# personal, hardware, network, system
set (PLUGCATEGORY "hardware")
# Set the Title to use for the Plug in the Overview and in the Titlebar
set (PLUGTITLE "Power")
set (PLUGDESCRIPTION "Power")
# The symbolic name of the Icon to use for the plug
set (PLUGICON "preferences-system-power")
# Set the version for the plug
set (VERSION "0.2.2")

project (pantheon-power)

#########################################################
# Only alter stuff below if you know what you are doing #
#########################################################

include (GNUInstallDirs)
set (DATADIR "${CMAKE_INSTALL_FULL_LIBDIR}/switchboard")
set (PKGDATADIR "${DATADIR}/${PLUGCATEGORY}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}-plug")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configure file
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)

add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Comment this out to enable C compiler warnings
add_definitions (-w)

# Traslation stuff
add_subdirectory (po)
# Info-plug
install (FILES ${resources} DESTINATION ${PKGDATADIR})

#Polkit Policy
configure_file (${CMAKE_SOURCE_DIR}/data/org.pantheon.switchboard.power.policy.cmake ${CMAKE_BINARY_DIR}/data/org.pantheon.switchboard.power.policy)
install (FILES ${CMAKE_BINARY_DIR}/data/org.pantheon.switchboard.power.policy DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/polkit-1/actions/)

add_subdirectory(src)
add_subdirectory(cli)
