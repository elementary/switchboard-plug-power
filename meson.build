project(
    'power',
    'vala', 'c',
    version: '2.5.0'
)

gettext_name = meson.project_name() + '-plug'
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

dbus_dep = dependency('dbus-1')
glib_dep = dependency('glib-2.0')
gio_dep = dependency('gio-2.0')
polkit_dep = dependency('polkit-gobject-1')

subdir('src')
subdir('cli')
subdir('data')
subdir('po')
