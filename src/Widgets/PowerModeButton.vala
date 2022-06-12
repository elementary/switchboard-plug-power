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
    public PowerProfile? pprofile { get; private set; default = null; }

    private Gtk.CheckButton saver_radio;
    private Gtk.CheckButton balanced_radio;
    private Gtk.CheckButton performance_radio;

    construct {
        try {
            pprofile = Bus.get_proxy_sync (BusType.SYSTEM, POWER_PROFILES_DAEMON_NAME, POWER_PROFILES_DAEMON_PATH, DBusProxyFlags.NONE);
        } catch (Error e) {
            critical (e.message);
            return;
        }

        var saver_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/power/32x32/apps/power-mode-powersaving.svg") {
            valign = Gtk.Align.FILL,
            vexpand = true,
            pixel_size = 32
        };

        var saver_label = new Gtk.Label (_("Power Saver")) {
            valign = Gtk.Align.FILL,
            vexpand = true
        };

        var saver_button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        saver_button_box.append (saver_icon);
        saver_button_box.append (saver_label);

        saver_radio = new Gtk.CheckButton ();
        saver_radio.get_style_context ().add_class ("image-button");
        saver_button_box.set_parent (saver_radio);

        var balanced_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/power/32x32/apps/power-mode-balanced.svg") {
            valign = Gtk.Align.FILL,
            vexpand = true,
            pixel_size = 32
        };

        var balanced_label = new Gtk.Label (_("Balanced")) {
            valign = Gtk.Align.FILL,
            vexpand = true
        };

        var balanced_button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        balanced_button_box.append (balanced_icon);
        balanced_button_box.append (balanced_label);

        balanced_radio = new Gtk.CheckButton () {
            group = saver_radio
        };
        balanced_radio.get_style_context ().add_class ("image-button");
        balanced_button_box.set_parent (balanced_radio);

        var performance_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/power/32x32/apps/power-mode-performance.svg") {
            valign = Gtk.Align.FILL,
            vexpand = true,
            pixel_size = 32
        };

        var performance_label = new Gtk.Label (_("Performance")) {
            valign = Gtk.Align.FILL,
            vexpand = true
        };

        var performance_button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        performance_button_box.append (performance_icon);
        performance_button_box.append (performance_label);

        performance_radio = new Gtk.CheckButton () {
            group = saver_radio
        };
        performance_radio.get_style_context ().add_class ("image-button");
        performance_button_box.set_parent (performance_radio);

        homogeneous = true;
        spacing = 6;

        for (int i = 0; i < pprofile.profiles.length; i++) {
            switch (pprofile.profiles[i].get ("Profile").get_string ()) {
                case "power-saver":
                    append (saver_radio);
                    break;
                case "balanced":
                    append (balanced_radio);
                    break;
                case "performance":
                    append (performance_radio);
                    break;
                default:
                    // Nothing to do for modes we don't support
                    break;
            }
        }

        update_active_profile ();

        ((DBusProxy) pprofile).g_properties_changed.connect (update_active_profile);

        saver_radio.toggled.connect (() => {
            pprofile.active_profile = "power-saver";
        });

        balanced_radio.toggled.connect (() => {
            pprofile.active_profile = "balanced";
        });

        performance_radio.toggled.connect (() => {
            pprofile.active_profile = "performance";
        });
    }

    private void update_active_profile () {
        switch (pprofile.active_profile) {
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
