/*
 * Copyright 2011–2021 elementary, Inc. (https://elementary.io)
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

public class Power.BehaviorView : Granite.SimpleSettingsPage {
    public Services.Device battery { get; private set; }
    public Gtk.Stack stack { get; private set; }
    private string path_battery = "";
    private Upower? upower = null;

    private const string NO_PERMISSION_STRING = _("You do not have permission to change this");
    private const string SETTINGS_DAEMON_NAME = "org.gnome.SettingsDaemon.Power";
    private const string SETTINGS_DAEMON_PATH = "/org/gnome/SettingsDaemon/Power";

    private Gtk.Scale scale;
    private PowerSettings screen;
    private PowerSupply power_supply;

    private enum PowerActionType {
        BLANK,
        SUSPEND,
        SHUTDOWN,
        HIBERNATE,
        INTERACTIVE,
        NOTHING,
        LOGOUT
    }

    public BehaviorView () {
        Object (
            icon_name: "preferences-system-power",
            title: _("Behavior")
        );
    }

    construct {
        try {
            upower = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, DBUS_UPOWER_PATH, DBusProxyFlags.NONE);
        } catch (Error e) {
            critical ("Connecting to UPower bus failed: %s", e.message);
        }
        get_dbus_main_battery_path ();
        content_area.halign = Gtk.Align.CENTER;
        content_area.row_spacing = 12;
        content_area.column_spacing = 12;

        var label_size = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

        settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
        if (path_battery != "") {
            battery = new Services.Device (path_battery);
        }
        power_supply = new PowerSupply ();

        try {
            screen = Bus.get_proxy_sync (BusType.SESSION, SETTINGS_DAEMON_NAME,
                SETTINGS_DAEMON_PATH, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
        } catch (IOError e) {
            warning ("Failed to get settings daemon for brightness setting");
        }

        var main_grid = new Gtk.Grid () {
            column_spacing = 12,
            margin = 24,
            row_spacing = 12
        };

        if (battery.is_present ()) {
            var wingpanel_power_settings = new GLib.Settings ("io.elementary.desktop.wingpanel.power");

            var show_percent_label = new Gtk.Label (_("Show battery percentage in Panel:")) {
                halign = Gtk.Align.END,
                xalign = 1
            };

            var show_percent_switch = new Gtk.Switch () {
                halign = Gtk.Align.START
            };
            wingpanel_power_settings.bind ("show-percentage", show_percent_switch, "active", SettingsBindFlags.DEFAULT);

            content_area.attach (show_percent_label, 0, 0);
            content_area.attach (show_percent_switch, 1, 0);
        }

        if (backlight_detect ()) {
            var brightness_label = new Gtk.Label (_("Display brightness:")) {
                halign = Gtk.Align.END,
                xalign = 1
            };

            var als_label = new Gtk.Label (_("Automatically adjust brightness:")) {
                xalign = 1
            };

            var als_switch = new Gtk.Switch ();
            als_switch.halign = Gtk.Align.START;

            settings.bind ("ambient-enabled", als_switch, "active", SettingsBindFlags.DEFAULT);

            scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10) {
                draw_value = false,
                hexpand = true,
                width_request = 480
            };

            scale.set_value (screen.brightness);

            scale.value_changed.connect (on_scale_value_changed);
            ((DBusProxy)screen).g_properties_changed.connect (on_screen_properties_changed);

            content_area.attach (brightness_label, 0, 1);
            content_area.attach (scale, 1, 1);
            content_area.attach (als_label, 0, 2);
            content_area.attach (als_switch, 1, 2);

            label_size.add_widget (brightness_label);
            label_size.add_widget (als_label);
        }

        if (lid_detect ()) {
            var lid_closed_label = new Gtk.Label (_("When lid is closed:")) {
                halign = Gtk.Align.END,
                xalign = 1
            };

            var lid_closed_box = new LidCloseActionComboBox (false);

            var lid_dock_label = new Gtk.Label (_("When lid is closed with external monitor:")) {
                halign = Gtk.Align.END,
                xalign = 1
            };

            var lid_dock_box = new LidCloseActionComboBox (true);

            label_size.add_widget (lid_closed_label);
            label_size.add_widget (lid_dock_label);

            var lock_image = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON) {
                sensitive = false,
                tooltip_text = NO_PERMISSION_STRING
            };

            var lock_image2 = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON) {
                sensitive = false,
                tooltip_text = NO_PERMISSION_STRING
            };

            content_area.attach (lid_closed_label, 0, 5);
            content_area.attach (lid_closed_box, 1, 5);
            content_area.attach (lock_image2, 2, 5);
            content_area.attach (lid_dock_label, 0, 6);
            content_area.attach (lid_dock_box, 1, 6);
            content_area.attach (lock_image, 2, 6);

            var permission = get_permission ();
            permission.bind_property ("allowed", lid_closed_box, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            permission.bind_property ("allowed", lid_closed_label, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            permission.bind_property ("allowed", lid_dock_box, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            permission.bind_property ("allowed", lid_dock_label, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            permission.bind_property ("allowed", lock_image, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
            permission.bind_property ("allowed", lock_image2, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
        }

        var screen_timeout_label = new Gtk.Label (_("Turn off display when inactive for:")) {
            halign = Gtk.Align.END,
            xalign = 1
        };

        var screen_timeout = new TimeoutComboBox (new GLib.Settings ("org.gnome.desktop.session"), "idle-delay");

        var power_label = new Gtk.Label (_("Power button:")) {
            halign = Gtk.Align.END,
            xalign = 1
        };

        var power_combobox = new ActionComboBox ("power-button-action");

        content_area.attach (screen_timeout_label, 0, 3);
        content_area.attach (screen_timeout, 1, 3);
        content_area.attach (power_label, 0, 4);
        content_area.attach (power_combobox, 1, 4);

        var sleep_timeout_label = new Gtk.Label (_("Suspend when inactive for:")) {
            xalign = 1
        };

        var sleep_timeout = new TimeoutComboBox (settings, "sleep-inactive-ac-timeout") {
            enum_property = "sleep-inactive-ac-type",
            enum_never_value = PowerActionType.NOTHING,
            enum_normal_value = PowerActionType.SUSPEND
        };

        var ac_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12
        };
        ac_grid.attach (sleep_timeout_label, 0, 1);
        ac_grid.attach (sleep_timeout, 1, 1);

        stack = new Gtk.Stack ();
        stack.add_titled (ac_grid, "ac", _("Plugged In"));

        var stack_switcher = new Gtk.StackSwitcher () {
            homogeneous = true,
            stack = stack
        };

        if (battery.is_present ()) {
            var battery_timeout_label = new Gtk.Label (_("Suspend when inactive for:")) {
                xalign = 1
            };
            label_size.add_widget (battery_timeout_label);

            var battery_timeout = new TimeoutComboBox (settings, "sleep-inactive-battery-timeout") {
                enum_property = "sleep-inactive-battery-type",
                enum_never_value = PowerActionType.NOTHING,
                enum_normal_value = PowerActionType.SUSPEND
            };

            var battery_grid = new Gtk.Grid () {
                column_spacing = 12,
                row_spacing = 12
            };
            battery_grid.attach (battery_timeout_label, 0, 1);
            battery_grid.attach (battery_timeout, 1, 1);

            stack.add_titled (battery_grid, "battery", _("On Battery"));

            var left_sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                hexpand = true,
                valign = Gtk.Align.CENTER
            };

            var right_sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                hexpand = true,
                valign = Gtk.Align.CENTER
            };

            var switcher_grid = new Gtk.Grid () {
                margin_top = 24,
                margin_bottom = 12
            };
            switcher_grid.add (left_sep);
            switcher_grid.add (stack_switcher);
            switcher_grid.add (right_sep);

            content_area.attach (switcher_grid, 0, 7, 2);
        }

        content_area.attach (stack, 0, 8, 2);

        var infobar_label = new Gtk.Label (_("Some changes will not take effect until you restart this computer"));

        var infobar = new Gtk.InfoBar ();
        infobar.message_type = Gtk.MessageType.WARNING;
        infobar.revealed = false;
        infobar.get_content_area ().add (infobar_label);

        var helper = LogindHelper.get_logind_helper ();
        if (helper != null) {
            helper.changed.connect (() => {
                infobar.revealed = true;
            });
        }

        add (infobar);

        add (content_area);
        show_all ();

        label_size.add_widget (sleep_timeout_label);
        label_size.add_widget (screen_timeout_label);
        label_size.add_widget (power_label);

        // hide stack switcher if we only have ac line
        stack_switcher.visible = stack.get_children ().length () > 1;
    }

    private static bool backlight_detect () {
        var interface_path = File.new_for_path ("/sys/class/backlight/");

        try {
            var enumerator = interface_path.enumerate_children (
            GLib.FileAttribute.STANDARD_NAME,
            FileQueryInfoFlags.NONE);
            FileInfo backlight;
            if ((backlight = enumerator.next_file ()) != null) {
                debug ("Detected backlight interface");
                return true;
            }

        enumerator.close ();

        } catch (GLib.Error err) {
            critical (err.message);
        }

        return false;
    }

    public static bool lid_detect () {
        var interface_path = File.new_for_path ("/proc/acpi/button/lid/");

        try {
            var enumerator = interface_path.enumerate_children (
            GLib.FileAttribute.STANDARD_NAME,
            FileQueryInfoFlags.NONE);
            FileInfo lid;
            if ((lid = enumerator.next_file ()) != null) {
                debug ("Detected lid switch");
                return true;
            }

            enumerator.close ();

        } catch (GLib.Error err) {
            warning (err.message); // Not critical as this is eventually dealt with
        }

        return false;
    }

    private void on_scale_value_changed () {
        var val = (int) scale.get_value ();
        ((DBusProxy)screen).g_properties_changed.disconnect (on_screen_properties_changed);
        screen.brightness = val;
        ((DBusProxy)screen).g_properties_changed.connect (on_screen_properties_changed);
    }

    private void on_screen_properties_changed (Variant changed_properties, string[] invalidated_properties) {
        var changed_brightness = changed_properties.lookup_value ("Brightness", new VariantType ("i"));
        if (changed_brightness != null) {
            var val = screen.brightness;
            scale.value_changed.disconnect (on_scale_value_changed);
            scale.set_value (val);
            scale.value_changed.connect (on_scale_value_changed);
        }
    }

    private void get_dbus_main_battery_path () {
        try {
            ObjectPath[] devs = upower.enumerate_devices ();
            for (int i = 0; i < devs.length; i++) {
                UpowerDevice device = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, devs[i].to_string (), DBusProxyFlags.GET_INVALIDATED_PROPERTIES);

                if (device.device_type == 2) {
                    path_battery = devs[i].to_string ();
                    break;
                }
            }
        } catch (Error e) {
            critical ("acpi couldn't get upower devices");
        }
    }
}
