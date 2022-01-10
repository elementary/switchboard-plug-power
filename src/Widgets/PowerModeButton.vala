/*
 * Copyright (c) 2011-2018 elementary LLC. (https://elementary.io)
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

namespace Power {
    public class PowerModeButton : Granite.Widgets.ModeButton {
        Gtk.Image power_saving_icon;
        Gtk.Image balanced_icon;
        Gtk.Image high_performance_icon;

        public bool profiles_available = true;

        public PowerModeButton () {
            try {
                PowerProfile pprofile = Bus.get_proxy_sync (BusType.SYSTEM, POWER_PROFILES_DAEMON_NAME, POWER_PROFILES_DAEMON_PATH, DBusProxyFlags.NONE);
                List<string> available_profiles = get_available_power_profiles (pprofile);
                if (available_profiles.length () > 1) {
                    for (int i = 0; i < available_profiles.length (); i++) {
                        switch (available_profiles.nth_data (i)) {
                            case "power-saver":
                            power_saving_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/power/32x32/apps/power-mode-powersaving.svg");
                            var power_saving_label = new Gtk.Label (_("Power Saver"));
                            var power_saving_button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                            power_saving_button_box.pack_start (power_saving_icon);
                            power_saving_button_box.pack_end (power_saving_label);
                            append (power_saving_button_box);
                            break;
                            case "balanced":
                            balanced_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/power/32x32/apps/power-mode-balanced.svg");
                            var balanced_label = new Gtk.Label (_("Balanced"));
                            var balanced_button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                            balanced_button_box.pack_start (balanced_icon);
                            balanced_button_box.pack_end (balanced_label);
                            append (balanced_button_box);
                            break;
                            case "performance":
                            high_performance_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/power/32x32/apps/power-mode-performance.svg");
                            var high_performance_label = new Gtk.Label (_("High Performance"));
                            var high_performance_button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                            high_performance_button_box.pack_start (high_performance_icon);
                            high_performance_button_box.pack_end (high_performance_label);
                            append (high_performance_button_box);
                            break;
                        }
                    }
                    for (int i = 0; i < available_profiles.length (); i++) {
                        if (pprofile.active_profile == available_profiles.nth_data (i)) {
                            this.selected = i;
                            break;
                        }
                    }

                    this.mode_changed.connect (() => {
                        pprofile.active_profile = available_profiles.nth_data (this.selected);
                    });
                } else {
                    profiles_available = false;
                }
            } catch (Error e) {
                profiles_available = false;
                append (new Gtk.Label (_("Not Available!")));
            }
        }

        private List<string> get_available_power_profiles (PowerProfile pprofile) {
            List<string> profiles = new List<string> ();
            for (int j = 0; j < pprofile.profiles.length; j++) {
                profiles.append (pprofile.profiles[j].get ("Profile").get_string ());
            }
            return profiles;
        }
    }
}
