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
    public class Battery : Object {
        private Upower? upower;
        private UpowerDevice? upower_device;

        private string dbus_upower_battery_path;

        construct {
            try {
                upower = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, DBUS_UPOWER_PATH, DBusProxyFlags.NONE);
                dbus_upower_battery_path = get_dbus_path (upower);
                if (dbus_upower_battery_path != "" && dbus_upower_battery_path != null) {
                    upower_device = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, dbus_upower_battery_path, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
                    debug ("Connection to UPower bus established");
                    debug ("Battery detected at path: %s", dbus_upower_battery_path);
                }
            } catch (Error e) {
                critical ("Connecting to UPower bus failed: %s", e.message);
            }
        }

        public bool is_present () {
            if (upower != null && upower_device != null && (upower.on_battery || upower_device.is_present)) {
                return true;
            }

            return false;
        }

        private string get_dbus_path (Upower upow) {
            string path = "";
            try {
                ObjectPath[] devs = upow.enumerate_devices ();
                for (int i = 0; i < devs.length; i++) {
                    UpowerDevice device = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, devs[i].to_string (), DBusProxyFlags.GET_INVALIDATED_PROPERTIES);

                    if (device.device_type == 2) {
                        path = devs[i].to_string ();
                        break;
                    }
                }
            } catch (Error e) {
                critical ("acpi couldn't get upower devices");
            }

            return path;
        }
    }
}
