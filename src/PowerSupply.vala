/*
 * Copyright (c) 2011-2015 elementary Developers (https://launchpad.net/elementary)
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
    public class PowerSupply {
        private Upower? upower;
        private UpowerDevice? upower_device;
        private UpowerProperties? device_properties;

        private const string dbus_upower_name = "org.freedesktop.UPower";
        private const string dbus_upower_root_path = "/org/freedesktop/UPower";
        private string dbus_upower_ac_path;
        
        public PowerSupply () {
            debug ("power supply init start");
            connect_dbus ();
            debug ("power supply init done");
        }


        public bool check_present () {
            bool return_value = false;
            bool supply = false;
            bool online = false;
            try {
                upower_device.Refresh ();
                supply = device_properties.Get (dbus_upower_ac_path, "PowerSupply").get_boolean ();
                online = device_properties.Get (dbus_upower_ac_path, "Online").get_boolean ();

                if (online && supply) {
                    return_value = true;
                }
            } catch (Error e) {
                warning ("power supply:%s", e.message);
            }
            return return_value;
        }

        private void connect_dbus() {
            try{
                upower = Bus.get_proxy_sync (BusType.SYSTEM, dbus_upower_name, dbus_upower_root_path);
                dbus_upower_ac_path = get_dbus_path(upower);
                debug ("power supply path:%s", dbus_upower_ac_path);
                if (dbus_upower_ac_path != "" && dbus_upower_ac_path != null) {
                    upower_device = Bus.get_proxy_sync (BusType.SYSTEM, dbus_upower_name, dbus_upower_ac_path);
                    device_properties = Bus.get_proxy_sync (BusType.SYSTEM, dbus_upower_name, dbus_upower_ac_path);
                }
            } catch (Error e) {
                critical ("power supply dbus connection to upower fault");
            }
            debug ("power supply connected dbus connections done");
        }

        private string get_dbus_path(Upower upow) {
            string return_value = "";
            try {
                ObjectPath[] devs = upow.EnumerateDevices();
                for(int i =0; i<devs.length; i++) {
                    if(devs[i].contains("AC")) {
                        return_value = devs[i].to_string();
                    }
                }
            } catch (Error e) {
                critical("power supply couldn't get upower devices");
            }
            return return_value;
        }
    }
}
