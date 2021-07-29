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
    public class PowerSupply {
        private Upower? upower;
        private UpowerDevice? upower_device;
        private const uint LINE_POWER_TYPE = 1;
        private bool dbus_upower_power_supply = false;

        public PowerSupply () {
            connect_dbus ();
        }

        public bool check_present () {
            bool present = false;
            if (dbus_upower_power_supply && upower_device != null) {
                try {
                    upower_device.refresh ();

                    if (upower_device.online && upower_device.power_supply) {
                        present = true;
                    }
                } catch (Error e) {
                    warning ("Error recieved from upower: %s", e.message);
                }
            }

            return present;
        }

        private void connect_dbus () {
            try {
                upower = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, DBUS_UPOWER_PATH, DBusProxyFlags.NONE);
                get_upower_ac_device (upower);
            } catch (Error e) {
                critical ("power supply dbus connection to upower fault");
            }
        }

        private void get_upower_ac_device (Upower upow) {
            try {
                ObjectPath[] devs = upow.enumerate_devices ();
                for (int i = 0; i < devs.length; i++) {
                    UpowerDevice dev = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, devs[i], DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
                    if (dev.device_type == LINE_POWER_TYPE) {
                        upower_device = dev;
                        dbus_upower_power_supply = true;
                        return;
                    }
                }
            } catch (Error e) {
                critical ("power supply couldn't get upower devices");
            }
        }
    }
}
