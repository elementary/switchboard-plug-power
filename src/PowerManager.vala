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

    public bool has_battery { get; private set; default = false; }
    public ListStore devices { get; private set; }

    private Upower? upower;

    construct {
        devices = new ListStore (typeof (Device));

        try {
            upower = Bus.get_proxy_sync (SYSTEM, UPOWER_NAME, UPOWER_PATH);
            upower.device_added.connect (on_device_added);
            upower.device_removed.connect (on_device_removed);

            try {
                foreach (unowned var path in upower.enumerate_devices ()) {
                    on_device_added (path);
                }
            } catch (Error e) {
                critical ("acpi couldn't get upower devices: %s", e.message);
            }
        } catch (Error e) {
            critical ("Connecting to UPower bus failed: %s", e.message);
        }
    }

    public bool on_battery () {
        return upower.on_battery;
    }

    public bool has_lid () {
        return upower.lid_is_present;
    }

    private void on_device_added (ObjectPath device_path) {
        var device = new Device (device_path);

        uint position = -1;
        var found = devices.find_with_equal_func (device, (EqualFunc<Device>) Device.equal_func, out position);

        if (!found) {
            devices.append (device);

            if (device.device_type == BATTERY) {
                has_battery = true;
            }
        }
    }

    private void on_device_removed (ObjectPath device_path) {
        uint position = -1;
        devices.find_with_equal_func (new Device (device_path), (EqualFunc<Device>) Device.equal_func, out position);

        if (position != -1) {
            devices.remove (position);
        }
    }
}
