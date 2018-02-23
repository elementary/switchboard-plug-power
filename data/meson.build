config_data = configuration_data()
config_data.set('GETTEXT_PACKAGE', gettext_name)
config_data.set('PKGDATADIR', join_paths(get_option('prefix'), get_option('datadir')))

configure_file(
    input: 'io.elementary.switchboard.power.policy.in',
    output: '@BASENAME@',
    configuration: config_data,
    install_dir: polkit_dep.get_pkgconfig_variable('policydir')
)
