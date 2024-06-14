config_data = configuration_data()
config_data.set('GETTEXT_PACKAGE', gettext_name)
config_data.set('PKGDATADIR', datadir)

configure_file(
    input: 'power.policy.in',
    output: 'io.elementary.settings.power.policy',
    configuration: config_data,
    install_dir: polkit_dep.get_pkgconfig_variable('policydir', define_variable: ['prefix', prefix])
)

i18n.merge_file(
    input: 'power.metainfo.xml.in',
    output: 'io.elementary.settings.power.metainfo.xml',
    po_dir: meson.source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: datadir / 'metainfo',
)
