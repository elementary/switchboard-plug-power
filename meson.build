project(
    'power',
    'vala', 'c',
    version: '2.3.5'
)

gettext_name = meson.project_name() + '-plug'
gnome = import('gnome')
i18n = import('i18n')

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
