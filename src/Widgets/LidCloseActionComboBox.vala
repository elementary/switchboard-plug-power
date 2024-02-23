/*
 * Copyright 2011-2018 elementary, Inc. (https://elementary.io)
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

class Power.LidCloseActionComboBox : Gtk.Widget {
    private const string HANDLE_LID_SWITCH_DOCKED_KEY = "HandleLidSwitchDocked";
    private const string HANDLE_LID_SWITCH_KEY = "HandleLidSwitch";

    public bool dock { get; construct; }

    private static Polkit.Permission? permission = null;

    private Gtk.ComboBoxText combobox;
    private int previous_active;

    public LidCloseActionComboBox (bool dock) {
        Object (dock: dock);
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    construct {
        combobox = new Gtk.ComboBoxText () {
            hexpand = true
        };

        combobox.set_parent (this);

        var helper = LogindHelper.get_logind_helper ();
        if (helper != null && helper.present) {
            combobox.append_text (_("Suspend"));
            combobox.append_text (_("Shutdown"));
            combobox.append_text (_("Lock"));
            combobox.append_text (_("Halt"));
            combobox.append_text (_("Do nothing"));
        } else {
            combobox.append_text (_("Not supported"));
        }

        update_current_action ();
        previous_active = combobox.active;
        combobox.changed.connect (on_changed);
    }

    // Returns true on success
    private async bool set_active_with_permission (int index_) {
        if (permission == null) {
            try {
                permission = yield new Polkit.Permission (
                    "io.elementary.settings.power.administration",
                    new Polkit.UnixProcess (Posix.getpid ())
                );
            } catch (Error e) {
                critical (e.message);
                return false;
            }
        }

        if (!permission.allowed) {
            try {
                yield permission.acquire_async ();
            } catch (Error e) {
                warning (e.message);
                return false;
            }
        }

        previous_active = combobox.active;
        combobox.active = index_;

        var helper = LogindHelper.get_logind_helper ();
        if (helper == null) {
            return false;
        }

        var action = get_action ();
        try {
            if (dock) {
                helper.set_key (HANDLE_LID_SWITCH_DOCKED_KEY, action.to_string ());
            } else {
                helper.set_key (HANDLE_LID_SWITCH_KEY, action.to_string ());
            }
        } catch (Error e) {
            warning (e.message);
        }

        return true;
    }

    private void on_changed () {
        if (combobox.active == previous_active) {
            return;
        }

        set_active_with_permission.begin (combobox.active, (obj, res) => {
            if (!set_active_with_permission.end (res)) {
                combobox.active = previous_active;
            }
        });
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
        switch (combobox.active) {
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
                combobox.active = 0;
                break;
            case LogindHelper.Action.POWEROFF:
                combobox.active = 1;
                break;
            case LogindHelper.Action.LOCK:
                combobox.active = 2;
                break;
            case LogindHelper.Action.HALT:
                combobox.active = 3;
                break;
            case LogindHelper.Action.IGNORE:
                combobox.active = 4;
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
