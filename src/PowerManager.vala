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

    private Upower? upower;

    construct {
        try {
            upower = Bus.get_proxy_sync (SYSTEM, UPOWER_NAME, UPOWER_PATH);
        } catch (Error e) {
            critical ("Connecting to UPower bus failed: %s", e.message);
        }
    }

    public bool has_battery () {
        if (upower.on_battery) {
            return true;
        };

        try {
            foreach (unowned var path in upower.enumerate_devices ()) {
                UpowerDevice device = Bus.get_proxy_sync (
                    SYSTEM,
                    UPOWER_NAME,
                    path.to_string (),
                    GET_INVALIDATED_PROPERTIES
                );

                if (device != null && device.device_type == 2 && device.is_present) {
                    return true;
                }
            }
        } catch (Error e) {
            critical ("acpi couldn't get upower devices: %s", e.message);
        }

        return false;
    }

    public bool on_battery () {
        return upower.on_battery;
    }

    public bool has_lid () {
        return upower.lid_is_present;
    }
}
