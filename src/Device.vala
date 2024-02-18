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
    public abstract string model { owned get; }
    public abstract uint32 battery_level { owned get; }
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

        public Icon? to_icon () {
            switch (this) {
                case CHARGING:
                    return new ThemedIcon ("device-charging-symbolic");
                case PENDING_CHARGE:
                case PENDING_DISCHARGE:
                    return new ThemedIcon ("device-charging-paused-symbolic");
                case EMPTY:
                case UNKNOWN:
                    return new ThemedIcon ("dialog-warning-symbolic");
                case DISCHARGING:
                case FULLY_CHARGED:
                default:
                    return null;
            }
        }

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

    /*
    * Need to verify power-supply before considering it a laptop battery.
    * Otherwise it will likely be the battery for a device of an unknown type.
    */
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
        PEN = 13;
    }

    public string path { get; construct; }

    /*
     * If the device is used to supply the system
     * TRUE for batteries and UPS, FALSE for mice and keyboards
     */
    public bool power_supply { get; private set; }
    public double percentage { get; private set; default = -1; }
    public bool coarse_battery_level { get; private set; default = false; }
    public string description { get; private set; }
    public string icon_name { get; private set; }
    public string model { get; private set; }
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
            power_supply = upower_device.power_supply;

            update_properties ();
            upower_device.g_properties_changed.connect (update_properties);

            update_description ();
            notify["percentage"].connect (update_description);
        } catch (IOError e) {
            critical (e.message);
        }
    }

    private void update_properties () {
        coarse_battery_level = upower_device.battery_level != 1;

        model = upower_device.model; // Can sometimes update eg when phone is trusted
        percentage = upower_device.percentage;
        state = upower_device.state;

        switch (device_type) {
            case UPS:
                icon_name = "uninterruptible-power-supply";
                break;
            case MOUSE:
                icon_name = "input-mouse";
                break;
            case KEYBOARD:
                icon_name =  "input-keyboard";
                break;
            case PDA:
            case PHONE:
                icon_name =  "phone";
                break;
            case MEDIA_PLAYER:
                icon_name =  "multimedia-player";
                break;
            case TABLET:
                icon_name = "input-touchpad";
                break;
            case PEN:
                icon_name =  "input-tablet";
                break;
            case GAMING_INPUT:
                icon_name =  "input-gaming";
                break;
            case COMPUTER:
                if (model == "iPad") {
                    icon_name = "computer-tablet";
                } else {
                    icon_name = "computer-laptop";
                }

                break;
            case MONITOR:
                icon_name =  "video-display";
                break;
            case LINE_POWER:
                icon_name =  "battery-ac-adapter";
                break;
            default:
                icon_name = "battery";
                break;
        }
    }

    private void update_description () {
        if (coarse_battery_level) {
            // Coarse battery level can sometimes be unknown, percentage is more reliable
            if (percentage < 20) {
                description = _("Critical");
            } else if (percentage < 40) {
                description = _("Low");
            } else if (percentage < 60) {
                description = _("Good");
            } else if (percentage < 80) {
                description = _("High");
            } else {
                description = _("Full");
            }
        } else {
            if (percentage == 0 && state == UNKNOWN) {
                description = _("Unknown. Device may be locked.");
            } else {
                description = "%.0f%%".printf (percentage);
            }
        }
    }

    public bool equal_func (Device other) {
        return this == other || this.path == other.path;
    }
}
