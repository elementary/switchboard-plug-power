helper_name = 'io.elementary.logind.helper'
helper_dir = libexecdir

config_data = configuration_data()
config_data.set('LIBEXEC', helper_dir)
config_data.set('CLI_EXEC_NAME', helper_name)

configure_file(
    input: 'io.elementary.logind.helper.service.in',
    output: '@BASENAME@',
    configuration: config_data,
    install_dir: dbus_dep.get_pkgconfig_variable('system_bus_services_dir')
)

install_data(
    'io.elementary.logind.helper.conf',
    install_dir: join_paths(dbus_dep.get_pkgconfig_variable('sysconfdir'), 'dbus-1', 'system.d')
)

executable(
    helper_name,
    'main.vala',
    'Server.vala',
    interfaces_file,
    dependencies: [
        glib_dep,
        gio_dep,
        polkit_dep
    ],
    install: true,
    install_dir : helper_dir
)
