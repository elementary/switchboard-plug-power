/*
 * Copyright (c) 2011-2016 elementary LLC. (https://launchpad.net/switchboard-plug-power)
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
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

namespace Power {
    class ActionComboBox : Gtk.ComboBoxText {

        public Gtk.Label label;
        private string key;

        // this maps combobox indices to gsettings enums
        private int[] map_to_sett = {0, 1, 2};
        // and vice-versa
        private int[] map_to_list = {0, 1, 2};

        public ActionComboBox (string label_name, string key_value) {
            key = key_value;
            label = new Gtk.Label (label_name);
            label.halign = Gtk.Align.END;
            ((Gtk.Misc) label).xalign = 1.0f;

            append_text (_("Do nothing"));
            append_text (_("Suspend"));
            append_text (_("Hibernate"));

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
