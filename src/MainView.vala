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

public class Power.MainView : Gtk.Grid {
    public Battery battery { get; private set; }
    public Gtk.Stack stack { get; private set; }

    /* Smooth scrolling support */
    public bool natural_scroll_touchpad { get; set; }
    public bool natural_scroll_mouse { get; set; }
    private double total_x_delta = 0;
    private double total_y_delta= 0;
    private const double SCROLL_MULTIPLIER = 5.0;

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

    private static Polkit.Permission? permission = null;

    construct {
        var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");
        touchpad_settings.bind ("natural-scroll", this, "natural-scroll-touchpad", SettingsBindFlags.GET);
        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
        mouse_settings.bind ("natural-scroll", this, "natural-scroll-mouse", SettingsBindFlags.GET);

        orientation = Gtk.Orientation.VERTICAL;
        margin_bottom = 12;

        var label_size = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

        settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");

        battery = new Battery ();
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

            main_grid.attach (show_percent_label, 0, 0);
            main_grid.attach (show_percent_switch, 1, 0);
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

            scale.scroll_event.connect ((e) => {
                double dir = 0.0;
                if (handle_scroll_event (e, out dir)) {
                    scale.set_value (Math.round ((scale.get_value () + dir * SCROLL_MULTIPLIER)));
                }

                return true;
            });

            scale.set_value (screen.brightness);

            scale.value_changed.connect (on_scale_value_changed);
            ((DBusProxy)screen).g_properties_changed.connect (on_screen_properties_changed);

            main_grid.attach (brightness_label, 0, 1);
            main_grid.attach (scale, 1, 1);
            main_grid.attach (als_label, 0, 2);
            main_grid.attach (als_switch, 1, 2);

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

            main_grid.attach (lid_closed_label, 0, 5);
            main_grid.attach (lid_closed_box, 1, 5);
            main_grid.attach (lid_dock_label, 0, 6);
            main_grid.attach (lid_dock_box, 1, 6);
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

        main_grid.attach (screen_timeout_label, 0, 3);
        main_grid.attach (screen_timeout, 1, 3);
        main_grid.attach (power_label, 0, 4);
        main_grid.attach (power_combobox, 1, 4);

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

            main_grid.attach (switcher_grid, 0, 7, 2);
        }

        main_grid.attach (stack, 0, 8, 2);

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

        var power_mode_button = new PowerModeButton () {
            halign = Gtk.Align.START
        };
        if (power_mode_button.pprofile != null) {
            var power_mode_label = new Gtk.Label (_("Power management mode:")) {
                xalign = 1
            };

            main_grid.attach (power_mode_label, 0, 9);
            main_grid.attach (power_mode_button, 1, 9);
        }

        add (main_grid);
        show_all ();

        label_size.add_widget (sleep_timeout_label);
        label_size.add_widget (screen_timeout_label);
        label_size.add_widget (power_label);

        // hide stack switcher if we only have ac line
        stack_switcher.visible = stack.get_children ().length () > 1;
    }

    public static Polkit.Permission? get_permission () {
        if (permission != null) {
            return permission;
        }

        try {
            permission = new Polkit.Permission.sync ("io.elementary.switchboard.power.administration", new Polkit.UnixProcess (Posix.getpid ()));
            return permission;
        } catch (Error e) {
            critical (e.message);
            return null;
        }
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

    private static bool lid_detect () {
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

    /* Handles both SMOOTH and non-SMOOTH events.
     * In order to deliver smooth volume changes it:
     * * accumulates very small changes until they become significant.
     * * ignores rapid changes in direction.
     * * responds to both horizontal and vertical scrolling.
     * In the case of diagonal scrolling, it ignores the event unless movement in one direction
     * is more than twice the movement in the other direction.
     */
     private bool handle_scroll_event (Gdk.EventScroll e, out double dir) {
        dir = 0.0;
        bool natural_scroll;
        var event_source = e.get_source_device ().input_source;
        if (event_source == Gdk.InputSource.MOUSE) {
            natural_scroll = natural_scroll_mouse;
        } else if (event_source == Gdk.InputSource.TOUCHPAD) {
            natural_scroll = natural_scroll_touchpad;
        } else {
            natural_scroll = false;
        }

        switch (e.direction) {
            case Gdk.ScrollDirection.SMOOTH:
                    var abs_x = double.max (e.delta_x.abs (), 0.0001);
                    var abs_y = double.max (e.delta_y.abs (), 0.0001);

                    if (abs_y / abs_x > 2.0) {
                        total_y_delta += e.delta_y;
                    } else if (abs_x / abs_y > 2.0) {
                        total_x_delta += e.delta_x;
                    }

                break;

            case Gdk.ScrollDirection.UP:
                total_y_delta = -1.0;
                break;
            case Gdk.ScrollDirection.DOWN:
                total_y_delta = 1.0;
                break;
            case Gdk.ScrollDirection.LEFT:
                total_x_delta = -1.0;
                break;
            case Gdk.ScrollDirection.RIGHT:
                total_x_delta = 1.0;
                break;
            default:
                break;
        }

        if (total_y_delta.abs () > 0.5) {
            dir = natural_scroll ? total_y_delta : -total_y_delta;
        } else if (total_x_delta.abs () > 0.5) {
            dir = natural_scroll ? -total_x_delta : total_x_delta;
        }
        warning (dir.to_string ());

        if (dir.abs () > 0.0) {
            total_y_delta = 0.0;
            total_x_delta = 0.0;
            return true;
        }

        return false;
    }
}
