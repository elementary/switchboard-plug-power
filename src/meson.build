interfaces_file = files('Interfaces.vala')

plug_files = files(
    'PowerSupply.vala',
    'Plug.vala',
    'Permission.vala',
    'LogindHelper.vala',
    'Battery.vala',
    'Widgets/TimeoutComboBox.vala',
    'Widgets/LidCloseActionComboBox.vala',
    'Widgets/ActionComboBox.vala',
)

switchboard_dep = dependency('switchboard-2.0')

shared_module(
    meson.project_name(),
    plug_files,
    interfaces_file,
    dependencies: [
        glib_dep,
        gio_dep,
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        polkit_dep,
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'hardware')
)
