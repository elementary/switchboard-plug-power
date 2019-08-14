config_data = configuration_data()
config_data.set('GETTEXT_PACKAGE', gettext_name)
config_data.set('PKGDATADIR', datadir)

configure_file(
    input: 'io.elementary.switchboard.power.policy.in',
    output: '@BASENAME@',
    configuration: config_data,
    install_dir: polkit_dep.get_pkgconfig_variable('policydir')
)

i18n.merge_file(
    input: 'power.appdata.xml.in',
    output: 'io.elementary.switchboard.power.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'xml',
    install: true,
    install_dir: join_paths(datadir, 'metainfo'),
)
