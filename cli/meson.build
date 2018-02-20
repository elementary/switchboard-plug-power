helper_name = 'io.elementary.logind.helper'
helper_dir = join_paths(get_option('prefix'), get_option('libexecdir'))

config_data = configuration_data()
config_data.set('LIBEXEC', helper_dir)
config_data.set('CLI_EXEC_NAME', helper_name)

configure_file(
    input: 'io.elementary.logind.helper.service.in',
    output: '@BASENAME@',
    configuration: config_data,
    install_dir: helper_dir
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
