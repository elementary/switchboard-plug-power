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
    class LidCloseActionComboBox : Gtk.Widget {
        private const string HANDLE_LID_SWITCH_DOCKED_KEY = "HandleLidSwitchDocked";
        private const string HANDLE_LID_SWITCH_KEY = "HandleLidSwitch";

        public bool dock { get; construct; }

        private Gtk.ComboBoxText main_widget;

        private int previous_active;

        public LidCloseActionComboBox (bool dock) {
            Object (dock: dock);
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

            var helper = LogindHelper.get_logind_helper ();
            if (helper != null && helper.present) {
                main_widget.append_text (_("Suspend"));
                main_widget.append_text (_("Shutdown"));
                main_widget.append_text (_("Lock"));
                main_widget.append_text (_("Halt"));
                main_widget.append_text (_("Do nothing"));
            } else {
                main_widget.append_text (_("Not supported"));
            }

            update_current_action ();
            previous_active = main_widget.active;

            main_widget.changed.connect (on_changed);
            main_widget.popup.connect (() => {
                var permission = MainView.get_permission ();
                if (permission == null) {
                    critical ("Permission is null");
                    return;
                }

                if (!permission.allowed) {
                    try {
                        permission.acquire ();
                    } catch (Error e) {
                        warning (e.message);
                        return;
                    }
                }
            });
            // main_widget.popdown (); does not work in connect
            main_widget.popup.connect_after (() => {
                var permission = MainView.get_permission ();
                if (permission == null || !permission.allowed) {
                    main_widget.popdown ();
                }
            });
        }

        private bool set_active_with_permission (int index_) {
            // Returns true on success

            var permission = MainView.get_permission ();
            if (permission == null) {
                return false;
            }

            if (!permission.allowed) {
                try {
                    permission.acquire ();
                } catch (Error e) {
                    warning (e.message);
                    return false;
                }
            }

            previous_active = main_widget.active;
            main_widget.active = index_;
            return true;
        }

        private void on_changed () {
            var helper = LogindHelper.get_logind_helper ();
            if (helper == null) {
                return;
            }

            if (main_widget.active != previous_active) {
                var success = set_active_with_permission (main_widget.active);
                if (!success) {
                    main_widget.active = previous_active;
                    return;
                }
            } else {
                return;
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
            switch (main_widget.active) {
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
                    main_widget.active = 0;
                    break;
                case LogindHelper.Action.POWEROFF:
                    main_widget.active = 1;
                    break;
                case LogindHelper.Action.LOCK:
                    main_widget.active = 2;
                    break;
                case LogindHelper.Action.HALT:
                    main_widget.active = 3;
                    break;
                case LogindHelper.Action.IGNORE:
                    main_widget.active = 4;
                    break;
                default:
                    break;
            }
        }

        ~LidCloseActionComboBox () {
            while (this.get_last_child () != null) {
                this.get_last_child ().unparent ();
            }
        }
    }
}
