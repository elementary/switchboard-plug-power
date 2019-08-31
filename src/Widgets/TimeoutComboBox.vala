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
    class TimeoutComboBox : Gtk.ComboBoxText {

        private Greeter.AccountsService? greeter_act = null;

        private string? _enum_property = null;
        public string? enum_property {
            get {
                return _enum_property;
            }
            set {
                if (value != _enum_property) {
                    _enum_property = value;
                    update_combo ();
                }
            }
        }

        private int _enum_never_value = -1;
        public int enum_never_value {
            get {
                return _enum_never_value;
            }
            set {
                if (value != _enum_never_value) {
                    _enum_never_value = value;
                    update_combo ();
                }
            }
        }

        private int _enum_normal_value = -1;
        public int enum_normal_value {
            get {
                return _enum_normal_value;
            }
            set {
                if (value != _enum_normal_value) {
                    _enum_normal_value = value;
                    update_combo ();
                }
            }
        }

        private GLib.Settings schema;
        private string key;

        private const int SECS_IN_MINUTE = 60;
        private const int[] timeout = {
            0,
            5 *  SECS_IN_MINUTE,
            10 * SECS_IN_MINUTE,
            15 * SECS_IN_MINUTE,
            30 * SECS_IN_MINUTE,
            45 * SECS_IN_MINUTE,
            60 * SECS_IN_MINUTE,
            120 * SECS_IN_MINUTE
        };

        public TimeoutComboBox (GLib.Settings schema_name, string key_value) {
            key = key_value;
            schema = schema_name;

            append_text (_("Never"));
            append_text (_("5 min"));
            append_text (_("10 min"));
            append_text (_("15 min"));
            append_text (_("30 min"));
            append_text (_("45 min"));
            append_text (_("1 hour"));
            append_text (_("2 hours"));

            hexpand = true;

            setup_accountsservice.begin ();

            update_combo ();

            changed.connect (update_settings);
            schema.changed[key].connect (update_combo);
        }

        private async void setup_accountsservice () {
            try {
                var accounts_service = yield GLib.Bus.get_proxy<FDO.Accounts> (GLib.BusType.SYSTEM,
                                                                               "org.freedesktop.Accounts",
                                                                               "/org/freedesktop/Accounts");
                var user_path = accounts_service.find_user_by_name (GLib.Environment.get_user_name ());

                greeter_act = yield GLib.Bus.get_proxy (GLib.BusType.SYSTEM,
                                                        "org.freedesktop.Accounts",
                                                        user_path,
                                                        GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
            } catch (Error e) {
                warning ("Unable to get AccountsService proxy, greeter power settings may be incorrect");
            }
        }

        private void update_settings () {
            if (enum_property != null && enum_never_value != -1 && enum_normal_value != -1) {
                if (active == 0) {
                    schema.set_enum (enum_property, enum_never_value);
                } else {
                    schema.set_enum (enum_property, enum_normal_value);
                }
            }

            schema.set_int (key, timeout[active]);

            if (greeter_act != null) {
                if (key == "sleep-inactive-ac-timeout") {
                    greeter_act.sleep_inactive_ac_timeout = timeout[active];
                    greeter_act.sleep_inactive_ac_type = schema.get_enum (enum_property);
                } else if (key == "sleep-inactive-battery-timeout") {
                    greeter_act.sleep_inactive_battery_timeout = timeout[active];
                    greeter_act.sleep_inactive_battery_type = schema.get_enum (enum_property);
                }
            }
        }

        // find closest timeout to our level
        private int find_closest (int second) {
            int key = 0;

            foreach (int i in timeout) {
                if (second > i)
                    key++;
                else
                    break;
            }

            return key;
        }

        private void update_combo () {
            int val = schema.get_int (key);

            if (enum_property != null && enum_never_value != -1 && enum_normal_value != -1) {
                var enum_value = schema.get_enum (enum_property);
                if (enum_value == enum_never_value) {
                    active = 0;
                    return;
                }
            }

            // need to process value to comply our timeout level
            active = find_closest (val);
        }
    }
}
