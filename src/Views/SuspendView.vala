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

public class Power.SuspendView : Granite.SimpleSettingsPage {
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

    public SuspendView () {
        Object (
            icon_name: "system-suspend",
            title: _("Suspend")
        );
    }

    construct {
        content_area.row_spacing = 6;
        margin_bottom = 12;

        var label_size = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

        settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
        elementary_dpms_settings = new GLib.Settings ("io.elementary.dpms");

        var sleep_timeout_label = new Gtk.Label (_("Suspend when inactive for:"));
        sleep_timeout_label.xalign = 1;

        var sleep_timeout = new TimeoutComboBox (settings, "sleep-inactive-ac-timeout");
        sleep_timeout.enum_property = "sleep-inactive-ac-type";
        sleep_timeout.enum_never_value = PowerActionType.NOTHING;
        sleep_timeout.enum_normal_value = PowerActionType.SUSPEND;

        content_area.attach (sleep_timeout_label, 0, 1);
        content_area.attach (sleep_timeout, 1, 1);
        show_all ();

        label_size.add_widget (sleep_timeout_label);
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
}
