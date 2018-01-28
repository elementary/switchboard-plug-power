/*
 * Copyright (c) 2018 elementary LLC. (https://launchpad.net/switchboard-plug-power)
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
    public class Lid : Object {
        private Upower? upower;

        construct {
            try {
                upower = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, DBUS_UPOWER_PATH, DBusProxyFlags.NONE);
                debug ("Connection to UPower bus established");
            } catch (Error e) {
                critical ("Connecting to UPower bus failed: %s", e.message);
            }
        }

        public bool is_present () {
            bool present = false;
            if (upower.lid_is_present) {
                present = true;
            }

            return present;
        }
    }
}
