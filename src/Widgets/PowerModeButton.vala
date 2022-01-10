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

    private Gtk.RadioButton saver_radio;
    private Gtk.RadioButton balanced_radio;
    private Gtk.RadioButton performance_radio;

    construct {
        try {
            pprofile = Bus.get_proxy_sync (BusType.SYSTEM, POWER_PROFILES_DAEMON_NAME, POWER_PROFILES_DAEMON_PATH, DBusProxyFlags.NONE);
        } catch (Error e) {
            critical (e.message);
            return;
        }

        var saver_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/power/32x32/apps/power-mode-powersaving.svg");

        var saver_label = new Gtk.Label (_("Power Saver"));

        var saver_button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        saver_button_box.pack_start (saver_icon);
        saver_button_box.pack_end (saver_label);

        saver_radio = new Gtk.RadioButton (null);
        saver_radio.get_style_context ().add_class ("image-button");
        saver_radio.add (saver_button_box);

        var balanced_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/power/32x32/apps/power-mode-balanced.svg");

        var balanced_label = new Gtk.Label (_("Balanced"));

        var balanced_button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        balanced_button_box.pack_start (balanced_icon);
        balanced_button_box.pack_end (balanced_label);

        balanced_radio = new Gtk.RadioButton.from_widget (saver_radio);
        balanced_radio.get_style_context ().add_class ("image-button");
        balanced_radio.add (balanced_button_box);

        var performance_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/power/32x32/apps/power-mode-performance.svg");

        var performance_label = new Gtk.Label (_("Performance"));

        var performance_button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        performance_button_box.pack_start (performance_icon);
        performance_button_box.pack_end (performance_label);

        performance_radio = new Gtk.RadioButton.from_widget (saver_radio);
        performance_radio.get_style_context ().add_class ("image-button");
        performance_radio.add (performance_button_box);

        homogeneous = true;
        spacing = 6;

        for (int i = 0; i < pprofile.profiles.length; i++) {
            switch (pprofile.profiles[i].get ("Profile").get_string ()) {
                case "power-saver":
                    add (saver_radio);
                    break;
                case "balanced":
                    add (balanced_radio);
                    break;
                case "performance":
                    add (performance_radio);
                    break;
            }
        }

        update_active_profile ();

        pprofile.changed.connect (() => {
            update_active_profile ();
        });

        saver_radio.clicked.connect (() => {
            pprofile.active_profile = "power-saver";
        });

        balanced_radio.clicked.connect (() => {
            pprofile.active_profile = "balanced";
        });

        performance_radio.clicked.connect (() => {
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
