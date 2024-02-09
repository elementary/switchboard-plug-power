/*
 * Copyright 2021-2022 elementary, Inc. (https://elementary.io)
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
 *
 * Authored by: Subhadeep Jasu <subhajasu@gmail.com>
 */

public class Power.PowerModeButton : Gtk.Box {
    public static bool successfully_initialized { get; private set; default = true; }

    private static PowerProfile? pprofile;
    private static GLib.Settings? settings;

    public string settings_key { get; construct; }

    private Gtk.CheckButton saver_radio;
    private Gtk.CheckButton balanced_radio;
    private Gtk.CheckButton performance_radio;

    public PowerModeButton (bool on_battery) {
        Object (settings_key: on_battery ? "profile-on-good-battery" : "profile-plugged-in");
    }

    static construct {
        var schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.settings-daemon.power", true);
        if (schema != null && schema.has_key ("profile-plugged-in") && schema.has_key ("profile-on-good-battery")) {
            settings = new GLib.Settings ("io.elementary.settings-daemon.power");
        } else {
            critical ("settings-daemon schema not found");
            successfully_initialized = false;
        }

        try {
            pprofile = Bus.get_proxy_sync (BusType.SYSTEM, POWER_PROFILES_DAEMON_NAME, POWER_PROFILES_DAEMON_PATH, DBusProxyFlags.NONE);
        } catch (Error e) {
            critical (e.message);
            successfully_initialized = false;
        }
    }

    construct {
        if (settings == null || pprofile == null) {
            return;
        }

        var header = new Granite.HeaderLabel (_("Power Mode")) {
            hexpand = true
        };

        var saver_icon = new Gtk.Image.from_icon_name ("power-mode-powersaver-symbolic") {
            icon_size = LARGE
        };

        var saver_label = new Gtk.Label (_("Power Saver"));

        var saver_button_box = new Gtk.Box (HORIZONTAL, 6);
        saver_button_box.append (saver_icon);
        saver_button_box.append (saver_label);

        saver_radio = new Gtk.CheckButton ();
        saver_radio.add_css_class ("image-button");
        saver_button_box.set_parent (saver_radio);

        var balanced_icon = new Gtk.Image.from_icon_name ("power-mode-balanced-symbolic") {
            icon_size = LARGE
        };

        var balanced_label = new Gtk.Label (_("Balanced"));

        var balanced_button_box = new Gtk.Box (HORIZONTAL, 6);
        balanced_button_box.append (balanced_icon);
        balanced_button_box.append (balanced_label);

        balanced_radio = new Gtk.CheckButton () {
            group = saver_radio
        };
        balanced_radio.add_css_class ("image-button");
        balanced_button_box.set_parent (balanced_radio);

        var performance_icon = new Gtk.Image.from_icon_name ("power-mode-performance-symbolic") {
            icon_size = LARGE
        };

        var performance_label = new Gtk.Label (_("Performance"));

        var performance_button_box = new Gtk.Box (HORIZONTAL, 6);
        performance_button_box.append (performance_icon);
        performance_button_box.append (performance_label);

        performance_radio = new Gtk.CheckButton () {
            group = saver_radio
        };
        performance_radio.add_css_class ("image-button");
        performance_button_box.set_parent (performance_radio);

        orientation = VERTICAL;
        append (header);

        foreach (unowned var profile in pprofile.profiles) {
            switch (profile.get ("Profile").get_string ()) {
                case "power-saver":
                    append (saver_radio);
                    break;
                case "balanced":
                    append (balanced_radio);
                    break;
                case "performance":
                    append (performance_radio);
                    break;
            }
        }

        update_active_profile ();

        saver_radio.toggled.connect (() => {
            if (saver_radio.active) {
                settings.set_string (settings_key, "power-saver");
            }
        });

        balanced_radio.toggled.connect (() => {
            if (balanced_radio.active) {
                settings.set_string (settings_key, "balanced");
            }
        });

        performance_radio.toggled.connect (() => {
            if (performance_radio.active) {
                settings.set_string (settings_key, "performance");
            }
        });
    }

    private void update_active_profile () {
        switch (settings.get_string (settings_key)) {
            case "power-saver":
                saver_radio.active = true;
                break;
            case "balanced":
                balanced_radio.active = true;
                break;
            case "performance":
                performance_radio.active = true;
                break;
        }
    }
}
