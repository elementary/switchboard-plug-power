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
    class LidCloseActionComboBox : Gtk.ComboBoxText {
        private const string HANDLE_LID_SWITCH_DOCKED_KEY = "HandleLidSwitchDocked";
        private const string HANDLE_LID_SWITCH_KEY = "HandleLidSwitch";

        private bool dock;

        private int previous_active;

        public LidCloseActionComboBox (bool dock) {
            this.dock = dock;

            var helper = LogindHelper.get_logind_helper ();
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
            previous_active = active;
            changed.connect (on_changed);
        }

        private bool set_active_with_permission (int index_) {
            // Returns true on success

            var permission = MainView.get_permission ();
            if (!permission.allowed) {
                try {
                    permission.acquire ();
                } catch (Error e) {
                    warning (e.message);
                    return false;
                }
            }

            previous_active = active;
            active = index_;
            return true;
        }

        private void on_changed () {
            var helper = LogindHelper.get_logind_helper ();
            if (helper == null) {
                return;
            }

            if (active != previous_active) {
                var success = set_active_with_permission (active);
                if (!success) {
                    active = previous_active;
                    return;
                }
            }

            LogindHelper.Action action = get_action ();
            try {
                if (dock) {
                    helper.set_key (HANDLE_LID_SWITCH_DOCKED_KEY, action.to_string ());
                } else {
                    helper.set_key (HANDLE_LID_SWITCH_KEY, action.to_string ());
                }
            } catch (Error e) {
                warning (e.message);
            }

            //  update_current_action ();
        }

        private void update_current_action () {
            var helper = LogindHelper.get_logind_helper ();
            if (helper == null) {
                return;
            }

            LogindHelper.Action action;
            if (dock) {
                try {
                    string val = helper.get_key (HANDLE_LID_SWITCH_DOCKED_KEY);
                    action = LogindHelper.Action.from_string (val);
                } catch (Error e) {
                    // Default in logind.conf
                    action = LogindHelper.Action.IGNORE;
                }
            } else {
                try {
                    string val = helper.get_key (HANDLE_LID_SWITCH_KEY);
                    action = LogindHelper.Action.from_string (val);
                } catch (Error e) {
                    // Default in logind.conf
                    action = LogindHelper.Action.SUSPEND;
                }
            }

            set_active_item (action);
        }

        private LogindHelper.Action get_action () {
            switch (active) {
                case 0:
                    return LogindHelper.Action.SUSPEND;
                case 1:
                    return LogindHelper.Action.POWEROFF;
                case 2:
                    return LogindHelper.Action.LOCK;
                case 3:
                    return LogindHelper.Action.HALT;
                case 4:
                    return LogindHelper.Action.IGNORE;
                default:
                    return LogindHelper.Action.UNKNOWN;
            }
        }

        private void set_active_item (LogindHelper.Action action) {
            switch (action) {
                case LogindHelper.Action.SUSPEND:
                    active = 0;
                    break;
                case LogindHelper.Action.POWEROFF:
                    active = 1;
                    break;
                case LogindHelper.Action.LOCK:
                    active = 2;
                    break;
                case LogindHelper.Action.HALT:
                    active = 3;
                    break;
                case LogindHelper.Action.IGNORE:
                    active = 4;
                    break;
                default:
                    break;
            }
        }
    }
}
