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
    public const string DBUS_UPOWER_NAME = "org.freedesktop.UPower";
    public const string DBUS_UPOWER_PATH = "/org/freedesktop/UPower";
    public const string LOGIND_HELPER_NAME = "io.elementary.logind.helper";
    public const string LOGIND_HELPER_OBJECT_PATH = "/io/elementary/logind/helper";
    public const string HISTORY_TYPE_RATE = "rate";
    public const string HISTORY_TYPE_CHARGE = "charge";
    public const string STATISTICS_TYPE_CHARGING = "charging";
    public const string STATISTICS_TYPE_DISCHARGING = "discharging";
    public struct HistoryDataPoint {
        uint32 time;
        double value;
        uint32 state;
    }

    public struct StatisticsDataPoint {
        double value;
        double accuracy;
    }

    [DBus (name = "org.freedesktop.DBus")]
    public interface DBus : Object {
        [DBus (name = "GetConnectionUnixProcessID")]
        public abstract uint32 get_connection_unix_process_id (string name) throws Error;

        public abstract uint32 get_connection_unix_user (string name) throws Error;
    }

    [DBus (name = "io.elementary.logind.helper")]
    public interface LogindHelperIface : Object {
        public abstract bool present { get; }
        public abstract void set_key (string key, string value) throws Error;
        public abstract string get_key (string key) throws Error;
        public signal void changed ();
    }

    [DBus (name = "org.gnome.SettingsDaemon.Power.Screen")]
    interface PowerSettings : GLib.Object {
        public abstract int brightness {get; set; }
    }

    [DBus (name = "org.freedesktop.UPower.Device")]
    interface UpowerDevice : Object {
        public abstract HistoryDataPoint[] get_history (string type, uint32 timespan, uint32 resolution) throws GLib.Error;

        public abstract StatisticsDataPoint[] get_statistics (string type) throws GLib.Error;
        public abstract void refresh () throws Error;

        public signal void changed ();
        public abstract bool online { owned get; }
        public abstract bool power_supply { owned get; }
        public abstract bool is_present { owned get; }
        [DBus (name = "Type")]
        public abstract uint device_type { owned get; }
        public abstract bool has_history { public owned get; public set; }
        public abstract bool has_statistics { public owned get; public set; }
        public abstract bool is_rechargeable { public owned get; public set; }
        public abstract double capacity { public owned get; public set; }
        public abstract double energy { public owned get; public set; }
        public abstract double energy_empty { public owned get; public set; }
        public abstract double energy_full { public owned get; public set; }
        public abstract double energy_full_design { public owned get; public set; }
        public abstract double energy_rate { public owned get; public set; }
        public abstract double luminosity { public owned get; public set; }
        public abstract double percentage { public owned get; public set; }
        public abstract double temperature { public owned get; public set; }
        public abstract double voltage { public owned get; public set; }
        public abstract int64 time_to_empty { public owned get; public set; }
        public abstract int64 time_to_full { public owned get; public set; }
        public abstract string model { public owned get; public set; }
        public abstract string native_path { public owned get; public set; }
        public abstract string serial { public owned get; public set; }
        public abstract string vendor { public owned get; public set; }
        public abstract uint32 state { public owned get; public set; }
        public abstract uint32 technology { public owned get; public set; }
        public abstract uint32 Type { public owned get; public set; }
        public abstract uint64 update_time { public owned get; public set; }
    }

    [DBus (name = "org.freedesktop.UPower")]
    interface Upower : Object {
        public signal void changed ();
        public abstract bool on_battery { owned get; }
        public abstract bool low_on_battery { owned get; }
        public abstract ObjectPath[] enumerate_devices () throws Error;
    }
}
