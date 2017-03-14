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
    public class Battery : Object {
        private Upower? upower;
        private UpowerDevice? upower_device;

        private string dbus_upower_battery_path;

        public bool laptop { get; private set; default = false; }
        
        public Battery () {
            connect_dbus ();
        }

        public bool check_present () {
            bool present = false;
            if (laptop) {
                if (upower.on_battery || upower_device.is_present) {
                    present = true;
                }
            }  

            return present;
        }

        private string get_dbus_path (Upower upow) {
            string path = "";
            try {
                ObjectPath[] devs = upow.enumerate_devices();
                for (int i = 0; i < devs.length; i++) {
                    if (devs[i].contains ("BAT0")) {
                        path = devs[i].to_string();
                        break;
                    }
                }
            } catch (Error e) {
                critical("acpi couldn't get upower devices");
            }

            return path;
        }

        private void connect_dbus () {
            try {
                upower = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, DBUS_UPOWER_PATH, DBusProxyFlags.NONE);
                dbus_upower_battery_path = get_dbus_path(upower);
                if (dbus_upower_battery_path != "" && dbus_upower_battery_path != null) {
                    upower_device = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, dbus_upower_battery_path, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);

                    laptop = true;
                    debug ("battery path:%s , its a laptop, dbus connected", dbus_upower_battery_path);
                } else {
                    laptop = false;
                    debug ("it is a dekstop (laptops false)");
                }
            } catch (Error e) {
                critical ("battery dbus connection to upower fault");
            }
        }
    }
}
