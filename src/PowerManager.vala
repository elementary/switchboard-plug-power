/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2011-2024 elementary, Inc. (https://elementary.io)
 */

public class Power.PowerManager : Object {
    private const string UPOWER_NAME = "org.freedesktop.UPower";
    private const string UPOWER_PATH = "/org/freedesktop/UPower";

    private static Once<PowerManager> instance;
    public static unowned PowerManager get_default () {
        return instance.once (() => { return new PowerManager (); });
    }

    public HashTable<string, Device> devices { get; private set; }

    private Upower? upower;

    construct {
        devices = new HashTable<string, Device> (str_hash, str_equal);

        try {
            upower = Bus.get_proxy_sync (SYSTEM, UPOWER_NAME, UPOWER_PATH);

            try {
                foreach (unowned var path in upower.enumerate_devices ()) {
                    var device_path = path.to_string ();
                    devices[device_path] = new Device (device_path);
                }
            } catch (Error e) {
                critical ("acpi couldn't get upower devices: %s", e.message);
            }
        } catch (Error e) {
            critical ("Connecting to UPower bus failed: %s", e.message);
        }
    }

    public bool has_battery () {
        if (upower.on_battery) {
            return true;
        };

        var has_battery = false;
        devices.foreach ((path, device) => {
            if (device.device_type == BATTERY) {
                has_battery = true;
            }
        });

        return has_battery;
    }

    public bool on_battery () {
        return upower.on_battery;
    }

    public bool has_lid () {
        return upower.lid_is_present;
    }
}
