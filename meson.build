project(
    'power',
    'vala', 'c',
    version: '2.7.0'
)

gettext_name = 'io.elementary.settings.' + meson.project_name()
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))
libexecdir = join_paths(prefix, get_option('libexecdir'))

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

conf_data = configuration_data()
conf_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf_data.set_quoted('GETTEXT_PACKAGE', gettext_name)
conf_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: conf_data
)

dbus_dep = dependency('dbus-1')
glib_dep = dependency('glib-2.0')
gio_dep = dependency('gio-2.0')
polkit_dep = dependency('polkit-gobject-1')

plug_resources = gnome.compile_resources (
    'plug_resources',
    'data/icons.gresource.xml',
    source_dir: 'data'
)

subdir('src')
subdir('cli')
subdir('data')
subdir('po')
