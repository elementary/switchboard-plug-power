find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (CLI_DEPS REQUIRED glib-2.0 gio-2.0 polkit-gobject-1)

add_definitions (${CLI_DEPS_CFLAGS})

link_directories (${CLI_DEPS_LIBRARY_DIRS})

set (CLI_EXEC_NAME logind-helper)
configure_file (io.elementary.logind.helper.service.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.logind.helper.service)

vala_precompile (CLI_VALA_C ${CLI_EXEC_NAME}
    main.vala
    Server.vala
    ${CMAKE_SOURCE_DIR}/src/Interfaces.vala
PACKAGES
    glib-2.0
    gio-2.0
    polkit-gobject-1
)

add_executable(${CLI_EXEC_NAME} ${CLI_VALA_C})
target_link_libraries (${CLI_EXEC_NAME} ${CLI_DEPS_LIBRARIES})

install (TARGETS ${CLI_EXEC_NAME} DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.logind.helper.service DESTINATION share/dbus-1/system-services)
install (FILES io.elementary.logind.helper.conf DESTINATION /etc/dbus-1/system.d)
