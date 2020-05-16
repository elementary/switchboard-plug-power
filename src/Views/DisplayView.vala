/*
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

public class Power.DisplayView : Granite.SimpleSettingsPage {
    public Battery battery { get; private set; }
    public Gtk.Stack stack { get; private set; }

    private const string NO_PERMISSION_STRING = _("You do not have permission to change this");
    private const string SETTINGS_DAEMON_NAME = "org.gnome.SettingsDaemon.Power";
    private const string SETTINGS_DAEMON_PATH = "/org/gnome/SettingsDaemon/Power";

    private GLib.Settings elementary_dpms_settings;
    private Gtk.Scale scale;
    private PowerSettings screen;

    private enum PowerActionType {
        BLANK,
        SUSPEND,
        SHUTDOWN,
        HIBERNATE,
        INTERACTIVE,
        NOTHING,
        LOGOUT
    }

    public DisplayView () {
        Object (
            header: _("Power"),
            icon_name: "video-display",
            title: _("Display")
        );
    }

    construct {
        content_area.row_spacing = 6;
        margin_bottom = 12;

        var label_size = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

        settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
        elementary_dpms_settings = new GLib.Settings ("io.elementary.dpms");

        try {
            screen = Bus.get_proxy_sync (BusType.SESSION, SETTINGS_DAEMON_NAME,
                SETTINGS_DAEMON_PATH, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
        } catch (IOError e) {
            warning ("Failed to get settings daemon for brightness setting");
        }

        if (backlight_detect ()) {
            var brightness_label = new Gtk.Label (_("Display brightness:"));
            brightness_label.halign = Gtk.Align.END;
            brightness_label.xalign = 1;

            var als_label = new Gtk.Label (_("Automatically adjust brightness:"));
            als_label.xalign = 1;

            var als_switch = new Gtk.Switch ();
            als_switch.halign = Gtk.Align.START;

            settings.bind ("ambient-enabled", als_switch, "active", SettingsBindFlags.DEFAULT);

            scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10);
            scale.draw_value = false;
            scale.hexpand = true;
            scale.width_request = 480;

            scale.set_value (screen.brightness);

            scale.value_changed.connect (on_scale_value_changed);
            (screen as DBusProxy).g_properties_changed.connect (on_screen_properties_changed);

            content_area.attach (brightness_label, 0, 0, 1, 1);
            content_area.attach (scale, 1, 0, 1, 1);
            content_area.attach (als_label, 0, 1, 1, 1);
            content_area.attach (als_switch, 1, 1, 1, 1);

            label_size.add_widget (brightness_label);
            label_size.add_widget (als_label);
        }

        var screen_timeout_label = new Gtk.Label (_("Turn off display when inactive for:"));
        screen_timeout_label.halign = Gtk.Align.END;
        screen_timeout_label.xalign = 1;

        var screen_timeout = new TimeoutComboBox (elementary_dpms_settings, "standby-time");
        screen_timeout.changed.connect (run_dpms_helper);

        content_area.attach (screen_timeout_label, 0, 3, 1, 1);
        content_area.attach (screen_timeout, 1, 3, 1, 1);

        show_all ();

        label_size.add_widget (screen_timeout_label);

    }

    private static bool backlight_detect () {
        var interface_path = File.new_for_path ("/sys/class/backlight/");

        try {
            var enumerator = interface_path.enumerate_children (
            GLib.FileAttribute.STANDARD_NAME,
            FileQueryInfoFlags.NONE);
            FileInfo backlight;
            if ((backlight = enumerator.next_file ()) != null) {
                debug ("Detected backlight interface");
                return true;
            }

        enumerator.close ();

        } catch (GLib.Error err) {
            critical ("%s", err.message);
        }

        return false;
    }

    private void on_scale_value_changed () {
        var val = (int) scale.get_value ();
        (screen as DBusProxy).g_properties_changed.disconnect (on_screen_properties_changed);
        screen.brightness = val;
        (screen as DBusProxy).g_properties_changed.connect (on_screen_properties_changed);
    }

    private void on_screen_properties_changed (Variant changed_properties, string[] invalidated_properties) {
        var changed_brightness = changed_properties.lookup_value ("Brightness", new VariantType ("i"));
        if (changed_brightness != null) {
            var val = screen.brightness;
            scale.value_changed.disconnect (on_scale_value_changed);
            scale.set_value (val);
            scale.value_changed.connect (on_scale_value_changed);
        }
    }

    private static void run_dpms_helper () {
        try {
            string[] argv = { "io.elementary.dpms-helper" };
            Process.spawn_async (null, argv, Environ.get (),
                SpawnFlags.SEARCH_PATH | SpawnFlags.STDERR_TO_DEV_NULL | SpawnFlags.STDOUT_TO_DEV_NULL,
                null, null);
        } catch (SpawnError e) {
            warning ("Failed to reset dpms settings: %s", e.message);
        }
    }
}
