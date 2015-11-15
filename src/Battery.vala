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
    public class Battery {

        private const string dbus_upower_name = "org.freedesktop.UPower";
        private const string dbus_upower_root_path = "/org/freedesktop/UPower";

        private const string[] state_known = { 
            "Unknown", "Charging", "Discharging", "Empty",
            "Fully charged", "Pending charge", "Pending discharge",
            "unknown" };

        private const string[] technology_known = { 
            "Unknown", "Lithium ion", "Lithium polymer", "Lithium iron phosphate",
            "Lead acid", "Nickel cadmium", "Nickel metal hydride",
            "unknown" };

        private const string[] type_known = { 
            "Unknown", "Line Power", "Battery", "Ups",
            "Monitor", "Mouse", "Keyboard",
            "Pda", "Phone" };

        private Upower? upower;
        private UpowerDevice? upower_device;
        private UpowerProperties? device_properties;

        private string dbus_upower_battery_path;
        private double drain_ratio;
        private double design_full_energy;
        private double last_full_energy;
        private double current_energy;
        private bool log_once = false;
        
        public bool present{ get; private set; }
        public string state{ get; private set; }
        public string technology{ get; private set; }
        public Time discharge_time{ get; private set; }
        public Time charge_to_full_time{ get; private set; }
        public double percentage_full{ get; private set; }
        public double temperature { get; private set; }
        public string battery_type { get; private set; }
        public bool laptop { get; private set; default = false; }
        
        public Battery () {
            debug ("Battery init start");
            connect_dbus ();
            debug ("Battery init done");
            load_info ();
        }

        public bool load_info () {
            bool succes = true;
            if (upower_device != null && upower != null) {
                try {
                    upower_device.Refresh ();
                    present = check_present ();
                    if (present) {
                        update_data ();                                           
                    }
                } catch (Error e) {
                    warning ("battery:%s", e.message);
                    succes = false;
                }
            }
            return succes;
        }

        private bool check_present () {
            bool return_value = false;
            if (laptop) {
                try {
                    if (upower.OnBattery) {
                        return_value = true;
                    } else if (device_properties.Get (dbus_upower_battery_path, "IsPresent").get_boolean ()) {
                        return_value = true;
                    }
                } catch (Error e) {
                    warning ("battery:%s", e.message);
                }   
            }         
            return return_value;
        }

        private void log_data (int64 time_seconds) {
            if(!log_once) {
                debug ("battery percentage full: %f", percentage_full);
                debug ("battery Upower battery ispresent: %s", present.to_string());
                debug ("battery state: %s", state);
                debug ("battery design_full_capacity: %f", design_full_energy);
                debug ("battery last_full_capacity: %f", last_full_energy);
                debug ("battery drain ratio: %f", drain_ratio);
                debug ("battery current_energy: %f", current_energy);
                debug ("time to discharging in minutes: %d", (int) (time_seconds/60));
                debug ("battery temperature: %f", temperature);
                debug ("battery Technology: %s", technology);
                log_once = true;
            }
        }

        private void update_data () {
            try {
                uint32 tmp_state = device_properties.Get (dbus_upower_battery_path, "State").get_uint32 ();
                state = check_state (tmp_state);
                design_full_energy = device_properties.Get (dbus_upower_battery_path, "EnergyFullDesign").get_double ();
                last_full_energy = device_properties.Get (dbus_upower_battery_path, "EnergyFull").get_double ();
                drain_ratio = device_properties.Get (dbus_upower_battery_path, "EnergyRate").get_double ();
                current_energy = device_properties.Get (dbus_upower_battery_path, "Energy").get_double ();
                int64 time_seconds = device_properties.Get (dbus_upower_battery_path, "TimeToEmpty").get_int64 ();
                temperature = device_properties.Get (dbus_upower_battery_path, "Temperature").get_double ();
                uint32 tech = device_properties.Get (dbus_upower_battery_path, "Technology").get_uint32 ();
                technology = check_technology (tech);
                percentage_full =  device_properties.Get (dbus_upower_battery_path, "Percentage").get_double ();
                uint32 tmp_type = device_properties.Get (dbus_upower_battery_path, "Type").get_uint32 ();
                battery_type = check_type (tmp_type);
                log_data (time_seconds);

                // this is for future use if needed.
                /*
                    is_present = device_properties.Get (dbus_upower_battery_path, "IsPresent").get_boolean ();
                    online = device_properties.Get (dbus_upower_battery_path, "Online").get_boolean ();
                    power_supply = device_properties.Get (dbus_upower_battery_path, "PowerSupply").get_boolean ();
                    capacity = device_properties.Get (dbus_upower_battery_path, "Capacity").get_double ();
                    energy_empty = device_properties.Get (dbus_upower_battery_path, "EnergyEmpty").get_double ();
                    luminosity = device_properties.Get (dbus_upower_battery_path, "Luminosity").get_double ();
                    voltage = device_properties.Get (dbus_upower_battery_path, "Voltage").get_double ();
                    time_to_full = device_properties.Get (dbus_upower_battery_path, "TimeToFull").get_int64 ();
                    
                    update_time = device_properties.Get (dbus_upower_battery_path, "UpdateTime").get_uint64 ();
                */
            } catch (Error e) {
                warning ("battery:%s", e.message);
            }
        }

        private string get_dbus_path(Upower upow) {
            string return_value = "";
            try {
                ObjectPath[] devs = upow.EnumerateDevices();
                for (int i =0; i<devs.length; i++) {
                    if (devs[i].contains("BAT0")) {
                        return_value = devs[i].to_string();
                    }
                }
            } catch (Error e) {
                critical("acpi couldn't get upower devices");
            }
            return return_value;
        }

        private void connect_dbus () {
            try {
                debug ("dbus connect");
                upower = Bus.get_proxy_sync (BusType.SYSTEM, dbus_upower_name, dbus_upower_root_path);
                dbus_upower_battery_path = get_dbus_path(upower);
                debug ("battery path:%s", dbus_upower_battery_path);
                if (dbus_upower_battery_path != "" && dbus_upower_battery_path != null) {
                    upower_device = Bus.get_proxy_sync (BusType.SYSTEM, dbus_upower_name, dbus_upower_battery_path);
                    device_properties = Bus.get_proxy_sync (BusType.SYSTEM, dbus_upower_name, dbus_upower_battery_path);
                    laptop = true;
                } else {
                    laptop = false;
                    debug ("it is a dekstop (laptops false)");
                }
            } catch (Error e) {
                critical ("battery dbus connection to upower fault");
            }
        }

        private string check_state (uint32 index) {
            return state_known [index];
        }

        private string check_technology (uint32 index) {
            return technology_known [index];
        }

        private string check_type (uint32 index) {
            return type_known [index];
        }
    }
}