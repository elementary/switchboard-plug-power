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
 */

namespace Power {
    class ActionComboBox : Gtk.ComboBoxText {
        public string key { get; construct; }

        private static GLib.Settings settings;

        // this maps combobox indices to gsettings enums
        private int[] map_to_sett = {0, 1, 3};
        // and vice-versa
        private int[] map_to_list = {0, 1, -1, 2};

        public ActionComboBox (string key_value) {
            Object (key: key_value);
        }

        static construct {
            settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
        }

        construct {
            append_text (_("Do nothing"));
            append_text (_("Suspend"));
            append_text (_("Prompt to shutdown"));

            hexpand = true;

            update_combo ();

            changed.connect (update_settings);
            settings.changed[key].connect (update_combo);
        }

        private void update_settings () {
            settings.set_enum (key, map_to_sett[active]);
        }

        private void update_combo () {
            int val = settings.get_enum (key);
            active = map_to_list [val];
        }
    }
}
