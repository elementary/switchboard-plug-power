/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.freedesktop.UPower.Device")]
public interface Power.UpowerDevice : DBusProxy {
    public signal void changed ();
    public abstract bool is_present { owned get; }
    public abstract bool online { owned get; }
    public abstract bool power_supply { owned get; }
    public abstract double percentage { owned get; }
    public abstract void refresh () throws Error;
    public abstract Device.State state { owned get; }
    [DBus (name = "Type")]
    public abstract Device.Type device_type { owned get; }
}

public class Power.Device : Object {
    private const string UPOWER_NAME = "org.freedesktop.UPower";

    [CCode (type_signature = "u")]
    public enum State {
        UNKNOWN = 0,
        CHARGING = 1,
        DISCHARGING = 2,
        EMPTY = 3,
        FULLY_CHARGED = 4,
        PENDING_CHARGE = 5,
        PENDING_DISCHARGE = 6;

        public string to_string () {
            switch (this) {
                case CHARGING:
                    return _("Charging");
                case DISCHARGING:
                    return _("Using battery power");
                case EMPTY:
                    return _("Empty");
                case FULLY_CHARGED:
                    return _("Fully charged");
                case PENDING_CHARGE:
                    return _("Waiting to charge");
                case PENDING_DISCHARGE:
                    return _("Waiting to use battery power");
                default:
                    return _("Unknown");
            }
        }
    }

    [CCode (type_signature = "u")]
    public enum Type {
        UNKNOWN = 0,
        LINE_POWER = 1,
        BATTERY = 2,
        UPS = 3,
        MONITOR = 4,
        MOUSE = 5,
        KEYBOARD = 6,
        PDA = 7,
        PHONE = 8,
        MEDIA_PLAYER = 9,
        TABLET = 10,
        COMPUTER = 11,
        GAMING_INPUT = 12,
        PEN = 13
    }

    public string path { get; construct; }
    public double percentage { get; private set; default = -1; }
    public State state { get; private set; default = UNKNOWN; }
    public Type device_type { get; private set; default = UNKNOWN; }

    private UpowerDevice upower_device;

    public Device (string path) {
        Object (path: path);
    }

    construct {
        try {
            upower_device = Bus.get_proxy_sync (
                SYSTEM,
                UPOWER_NAME,
                path,
                GET_INVALIDATED_PROPERTIES
            );

            device_type = upower_device.device_type;

            update_properties ();
            upower_device.g_properties_changed.connect (update_properties);
        } catch (IOError e) {
            critical (e.message);
        }
    }

    private void update_properties () {
        percentage = upower_device.percentage;
        state = upower_device.state;
    }
}
