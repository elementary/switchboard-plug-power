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
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

namespace Power {
    class LidCloseActionComboBox : Gtk.ComboBoxText {
        private const string HANDLE_LID_SWITCH_DOCKED_KEY = "HandleLidSwitchDocked";
        private const string HANDLE_LID_SWITCH_KEY = "HandleLidSwitch";

        public Gtk.Label label;
        private bool dock;

        public LidCloseActionComboBox (string label_name, bool dock) {
            label = new Gtk.Label (label_name);
            label.halign = Gtk.Align.END;
            ((Gtk.Misc) label).xalign = 1.0f;

            this.dock = dock;

            var helper = Utils.get_logind_helper ();
            if (helper != null && helper.present) {
                append_text (_("Suspend"));
                append_text (_("Shutdown"));
                append_text (_("Lock"));
                append_text (_("Halt"));
                append_text (_("Do nothing"));
            } else {
                append_text (_("Not supported"));
            }

            hexpand = true;
            update_current_action ();
            changed.connect (on_changed);
        }

        private void on_changed () {
            Utils.Action action = get_action ();

            var helper = Utils.get_logind_helper ();
            if (helper == null) {
                return;
            }

            if (dock) {
                helper.set_key (HANDLE_LID_SWITCH_DOCKED_KEY, action.to_string ());
            } else {
                helper.set_key (HANDLE_LID_SWITCH_KEY, action.to_string ());
            }

            update_current_action ();
        }

        private void update_current_action () {
            var helper = Utils.get_logind_helper ();
            if (helper == null) {
                return;
            }

            if (dock) {
                Utils.Action action;
                try {
                    string val = helper.get_key (HANDLE_LID_SWITCH_DOCKED_KEY);
                    action = Utils.Action.from_string (val);
                } catch (Error e) {
                    // Default in logind.conf
                    action = Utils.Action.IGNORE;
                }

                set_active_item (action);
            } else {
                Utils.Action action;
                try {
                    string val = helper.get_key (HANDLE_LID_SWITCH_KEY);
                    action = Utils.Action.from_string (val);
                } catch (Error e) {
                    // Default in logind.conf
                    action = Utils.Action.SUSPEND;
                }

                set_active_item (action);
            }
        }

        private Utils.Action get_action () {
            switch (active) {
                case 0:
                    return Utils.Action.SUSPEND;
                case 1:
                    return Utils.Action.POWEROFF;
                case 2:
                    return Utils.Action.LOCK;
                case 3:
                    return Utils.Action.HALT;
                case 4:
                    return Utils.Action.IGNORE;
                default:
                    return Utils.Action.UNKNOWN;
            }
        }

        private void set_active_item (Utils.Action action) {
            switch (action) {
                case Utils.Action.SUSPEND:
                    active = 0;
                    break;
                case Utils.Action.POWEROFF:
                    active = 1;
                    break;
                case Utils.Action.LOCK:
                    active = 2;
                    break;
                case Utils.Action.HALT:
                    active = 3;
                    break;
                case Utils.Action.IGNORE:
                    active = 4;
                    break;
                default:
                    break;
            }
        }
    }
}
