interfaces_file = files('Interfaces.vala')

plug_files = files(
    'Device.vala',
    'GreeterAccountsServicePlugin.vala',
    'LogindHelper.vala',
    'MainView.vala',
    'Plug.vala',
    'PowerManager.vala',
    'Widgets/BatteryBox.vala',
    'Widgets/TimeoutComboBox.vala',
    'Widgets/LidCloseActionComboBox.vala',
    'Widgets/PowerModeButton.vala',
)

switchboard_dep = dependency('switchboard-3')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

shared_module(
    meson.project_name(),
    plug_files,
    plug_resources,
    conf_file,
    interfaces_file,
    dependencies: [
        adw_dep,
        glib_dep,
        gio_dep,
        dependency('gobject-2.0'),
        dependency('granite-7'),
        dependency('gtk4'),
        polkit_dep,
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'hardware')
)
