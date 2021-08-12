/*
 * Copyright 2011–2021 elementary, Inc. (https://launchpad.net/switchboard-plug-power)
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


public class Power.Services.Device : Object {
    [CCode (type_signature = "u")]
    public enum State {
        UNKNOWN = 0,
        CHARGING = 1,
        DISCHARGING = 2,
        EMPTY = 3,
        FULLY_CHARGED = 4,
        PENDING_CHARGE = 5,
        PENDING_DISCHARGE = 6
    }

    [CCode (type_signature = "u")]
    public enum Technology {
        UNKNOWN = 0,
        LITHIUM_ION = 1,
        LITHIUM_POLYMER = 2,
        LITHIUM_IRON_PHOSPHATE = 3,
        LEAD_ACID = 4,
        NICKEL_CADMIUM = 5,
        NICKEL_METAL_HYDRIDE = 6
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
        PEN = 13;

        public unowned string? get_name () {
            switch (this) {
                case BATTERY:
                    return _("Battery");
                case UPS:
                    return _("UPS");
                case MONITOR:
                    return _("Display");
                case MOUSE:
                    return _("Mouse");
                case KEYBOARD:
                    return _("Keyboard");
                case PDA:
                    return _("PDA");
                case PHONE:
                    return _("Phone");
                case MEDIA_PLAYER:
                    return _("Media Player");
                case TABLET:
                    return _("Tablet");
                case COMPUTER:
                    return _("Computer");
                case GAMING_INPUT:
                    return _("Controller");
                case PEN:
                    return _("Pen");
                case LINE_POWER:
                    return _("Plugged In");
                default:
                    return null;
            }
        }

        public unowned string? get_icon_name () {
            switch (this) {
                case UPS:
                    return "uninterruptible-power-supply";
                case MOUSE:
                    return "input-mouse";
                case KEYBOARD:
                    return "input-keyboard";
                case PDA:
                case PHONE:
                    return "phone";
                case MEDIA_PLAYER:
                    return "multimedia-player";
                case TABLET:
                case PEN:
                    return "input-tablet";
                case GAMING_INPUT:
                    return "input-gaming";
                case COMPUTER:
                case MONITOR:
                case UNKNOWN:
                case BATTERY:
                case LINE_POWER:
                default:
                    return null;
            }
        }
    }

    private Upower? upower;
    private UpowerDevice? upower_device;

    private string device_path = "";
    public double percentage { get; private set; }
    public bool is_charging { get; private set; }
    public bool is_a_battery { get; private set; }
    public bool has_history { get; private set; }
    public bool has_statistics { get; private set; }
    public bool is_rechargeable { get; private set; }
    public bool online { get; private set; }
    public bool power_supply { get; private set; }
    public double capacity { get; private set; }
    public double energy { get; private set; }
    public double energy_empty { get; private set; }
    public double energy_full { get; private set; }
    public double energy_full_design { get; private set; }
    public double energy_rate { get; private set; }
    public double luminosity { get; private set; }
    public double temperature { get; private set; }
    public double voltage { get; private set; }
    public int64 time_to_empty { get; private set; }
    public int64 time_to_full { get; private set; }
    public string model { get; private set; }
    public string native_path { get; private set; }
    public string serial { get; private set; }
    public string vendor { get; private set; }
    public uint64 update_time { get; private set; }
    public Type device_type { get; private set; }
    public Technology technology { get; private set; }
    public State state { get; private set; }

    public signal void properties_updated ();

    public Device (string device_path) {
        this.device_path = device_path;

        if (connect_to_bus ()) {
            update_properties ();
            connect_signals ();
        }
    }

    private bool connect_to_bus () {
        try {
            upower_device = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, device_path, DBusProxyFlags.NONE);
            debug (("Connection to UPower device %s established").printf (device_path));
        } catch (Error e) {
            critical ("Connecting to UPower device failed: %s", e.message);
        }

        return upower_device != null;
    }

    private void connect_signals () {
        //  upower_device.g_properties_changed.connect (update_properties);
    }

    private void update_properties () {
        try {
            upower_device.refresh ();
        } catch (Error e) {
            critical ("Updating the upower upower_device parameters failed: %s", e.message);
        }

        has_history = upower_device.has_history;
        has_statistics = upower_device.has_statistics;
        is_rechargeable = upower_device.is_rechargeable;
        online = upower_device.online;
        power_supply = upower_device.power_supply;
        capacity = upower_device.capacity;
        energy = upower_device.energy;
        energy_empty = upower_device.energy_empty;
        energy_full = upower_device.energy_full;
        energy_full_design = upower_device.energy_full_design;
        energy_rate = upower_device.energy_rate;
        luminosity = upower_device.luminosity;
        percentage = upower_device.percentage;
        temperature = upower_device.temperature;
        voltage = upower_device.voltage;
        time_to_empty = upower_device.time_to_empty;
        time_to_full = upower_device.time_to_full;
        model = upower_device.model;
        native_path = upower_device.native_path;
        serial = upower_device.serial;
        vendor = upower_device.vendor;
        device_type = determine_device_type ();
        state = (State) upower_device.state;
        technology = (Technology) upower_device.technology;
        update_time = upower_device.update_time;

        is_charging = state == State.FULLY_CHARGED || state == State.CHARGING;
        is_a_battery = device_type != Type.UNKNOWN && device_type != Type.LINE_POWER;

        properties_updated ();
    }

    public bool is_present () {
        bool present = false;
        if (upower.on_battery || upower_device.is_present) {
            present = true;
        }

        return present;
    }

    public string get_info () {
        var percent = (int)Math.round (percentage);
        if (percent <= 0) {
            return _("Calculating…");
        }

        if (percent == 100 && is_charging) {
            return _("Fully charged");
        }

        var info = _("%i%% charged").printf (percent);

        return info;
    }

    public string get_icon_name_for_battery () {
        if (!is_a_battery) {
            return "preferences-system-power-symbolic";
        }
        if (percentage == 100 && is_charging) {
            return "battery-full-charged";
        }
        var battery_icon = get_battery_icon ();
        if (is_charging) {
            return battery_icon + "-charging";
        } else {
            return battery_icon;
        }
    }

    public string get_battery_icon () {
        if (percentage <= 0) {
            return "battery-good";
        }

        if (percentage < 10 && (time_to_empty == 0 || time_to_empty < 30 * 60)) {
            return "battery-empty";
        }

        if (percentage < 30) {
            return "battery-caution";
        }

        if (percentage < 60) {
            return "battery-low";
        }

        if (percentage < 80) {
            return "battery-good";
        }

        return "battery-full";
    }

    public string get_current_charge () {
        return format_capacity (percentage, "%");
    }

    public string get_max_capacity () {
        return format_capacity (capacity, "%");
    }

    public string get_design_energy () {
        return format_capacity (energy_full_design, " Wh");
    }

    private static string format_capacity (double value, string unit) {
        var value_int = (int)Math.round (value);
        if (value_int == 0) {
            return _("Unknown");
        }

        return _("%i%s").printf (value_int, unit);
    }

    public string get_health () {
        var capacity = (int)Math.round (capacity);

        if (capacity == 0) {
            return _("Unknown");
        }

        if (capacity < 60) {
            ///TRANSLATORS: Battery capacity below 60%, considered critically low battery health
            return _("Critical");
        }

        if (capacity < 70) {
            ///TRANSLATORS: Battery capacity from 60 to 69%, considered poor battery health
            return _("Poor");
        }

        if (capacity < 80) {
            ///TRANSLATORS: Battery capacity from 70 to 79%, considered fair battery health
            return _("Fair");
        }

        if (capacity < 90) {
            ///TRANSLATORS: Battery capacity from 80 to 90%, considered good battery health
            return _("Good");
        }

        ///TRANSLATORS: Battery capacity above 90%, considered excellent battery health
        return _("Excellent");
    }

    private Type determine_device_type () {
        // In case an all-in-one keyboard is clasified as mouse because of a
        // mouse pointer, we should show it as keyboard.
        //
        // Upstream issue https://gitlab.freedesktop.org/upower/upower/-/issues/139
        if (upower_device.Type == Type.MOUSE && upower_device.model.contains ("keyboard")) {
            return (Type) Type.KEYBOARD;
        }

        return (Type) upower_device.Type;
    }
}
