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
    class ActionComboBox : Gtk.Widget {
        public string key { get; construct; }
        private Gtk.ComboBoxText main_widget;

        // this maps combobox indices to gsettings enums
        private int[] map_to_sett = {0, 1, 3};
        // and vice-versa
        private int[] map_to_list = {0, 1, -1, 2};

        public ActionComboBox (string key_value) {
            Object (key: key_value);
        }

        static construct {
            set_layout_manager_type (typeof (Gtk.BinLayout));
        }

        construct {
            main_widget = new Gtk.ComboBoxText () {
                hexpand = true
            };
            main_widget.set_parent (this);
            hexpand = true;

            main_widget.append_text (_("Do nothing"));
            main_widget.append_text (_("Suspend"));
            main_widget.append_text (_("Prompt to shutdown"));

            update_combo ();

            main_widget.changed.connect (update_settings);
            settings.changed[key].connect (update_combo);
        }

        private void update_settings () {
            settings.set_enum (key, map_to_sett[main_widget.active]);
        }

        private void update_combo () {
            int val = settings.get_enum (key);
            main_widget.active = map_to_list [val];
        }

        ~ActionComboBox () {
            while (this.get_last_child () != null) {
                this.get_last_child ().unparent ();
            }
        }
    }
}
