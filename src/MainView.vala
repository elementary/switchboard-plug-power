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

public class Power.MainView : Switchboard.SettingsPage {
    public Gtk.Stack stack { get; private set; }

    /* Smooth scrolling support */
    public bool natural_scroll_touchpad { get; set; }
    public bool natural_scroll_mouse { get; set; }
    private double total_x_delta = 0;
    private double total_y_delta= 0;
    private const double BRIGHTNESS_STEP = 4.0;

    private const string SETTINGS_DAEMON_NAME = "org.gnome.SettingsDaemon.Power";
    private const string SETTINGS_DAEMON_PATH = "/org/gnome/SettingsDaemon/Power";

    private Gtk.DropDown powerbutton_dropdown;
    private Gtk.Scale scale;
    private PowerSettings screen;

    private enum PowerActionType {
        BLANK,
        SUSPEND,
        SHUTDOWN,
        HIBERNATE,
        INTERACTIVE,
        NOTHING,
        LOGOUT
    }

    public MainView () {
        Object (
            title: _("Power"),
            icon: new ThemedIcon ("preferences-system-power")
        );
    }

    construct {
        var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");
        touchpad_settings.bind ("natural-scroll", this, "natural-scroll-touchpad", SettingsBindFlags.GET);
        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
        mouse_settings.bind ("natural-scroll", this, "natural-scroll-mouse", SettingsBindFlags.GET);

        var label_size = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

        settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");

        var power_manager = PowerManager.get_default ();

        try {
            screen = Bus.get_proxy_sync (BusType.SESSION, SETTINGS_DAEMON_NAME,
                SETTINGS_DAEMON_PATH, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
        } catch (IOError e) {
            warning ("Failed to get settings daemon for brightness setting");
        }

        var box = new Gtk.Box (VERTICAL, 24);

        if (power_manager.batteries.n_items > 0) {
            var battery_box = new BatteryBox () {
                margin_bottom = 12
            };

            box.append (battery_box);
        }

        var devices_box = new DevicesBox () {
            margin_bottom = 12
        };

        box.append (devices_box);

        if (screen.brightness != -1) {
            var als_switch = new Gtk.Switch () {
                halign = END
            };

            var als_label = new Gtk.Label (_("Automatically Adjust Brightness")) {
                mnemonic_widget = als_switch,
                xalign = 0
            };

            settings.bind ("ambient-enabled", als_switch, "active", SettingsBindFlags.DEFAULT);

            var scale_scroll_controller = new Gtk.EventControllerLegacy ();

            scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10) {
                hexpand = true
            };
            scale.add_controller (scale_scroll_controller);

            scale_scroll_controller.event.connect ((e) => {
                if (e.get_event_type () == Gdk.EventType.SCROLL) {
                    double dir = 0.0;
                    if (handle_scroll_event ((Gdk.ScrollEvent) e, out dir)) {
                        scale.set_value (scale.get_value () + Math.round (dir * BRIGHTNESS_STEP));
                    }

                    return Gdk.EVENT_STOP;
                }

                return Gdk.EVENT_PROPAGATE;
            });

            scale.set_value (screen.brightness);

            scale.value_changed.connect (on_scale_value_changed);
            ((DBusProxy)screen).g_properties_changed.connect (on_screen_properties_changed);

            var brightness_label = new Gtk.Label (_("Display Brightness")) {
                mnemonic_widget = scale,
                xalign = 0
            };

            var brightness_grid = new Gtk.Grid () {
                column_spacing = 12,
                row_spacing = 12
            };
            brightness_grid.attach (brightness_label, 0, 0);
            brightness_grid.attach (scale, 1, 0);
            brightness_grid.attach (als_label, 0, 1);
            brightness_grid.attach (als_switch, 1, 1);

            box.append (brightness_grid);

            label_size.add_widget (brightness_label);
            label_size.add_widget (als_label);
        }

        if (power_manager.has_lid ()) {
            var infobar_label = new Gtk.Label (_("Some changes will not take effect until you restart this computer"));

            var infobar = new Gtk.InfoBar () {
                message_type = WARNING,
                revealed = false
            };
            infobar.add_child (infobar_label);
            infobar.add_css_class (Granite.STYLE_CLASS_FRAME);

            var lid_closed_label = new Gtk.Label (_("Lid Close Behavior")) {
                xalign = 0
            };

            var lid_closed_box = new LidCloseActionComboBox (false) {
                hexpand = true
            };

            var lid_dock_label = new Gtk.Label (_("Lid Close With External Display")) {
                xalign = 0
            };

            var lid_dock_box = new LidCloseActionComboBox (true) {
                hexpand = true
            };

            label_size.add_widget (lid_closed_label);
            label_size.add_widget (lid_dock_label);

            var lid_close_grid = new Gtk.Grid () {
                row_spacing = 12,
                column_spacing = 12
            };
            lid_close_grid.attach (lid_closed_label, 0, 0);
            lid_close_grid.attach (lid_closed_box, 1, 0);
            lid_close_grid.attach (lid_dock_label, 0, 1);
            lid_close_grid.attach (lid_dock_box, 1, 1);
            lid_close_grid.attach (infobar, 0, 2, 2);

            box.append (lid_close_grid);

            var helper = LogindHelper.get_logind_helper ();
            if (helper != null) {
                helper.changed.connect (() => {
                    infobar.revealed = true;
                });
            }
        }

        var idle_dim_switch = new Gtk.Switch () {
            halign = END
        };

        var idle_dim_label = new Gtk.Label (_("Automatically Dim Display")) {
            mnemonic_widget = idle_dim_switch,
            xalign = 0
        };

        label_size.add_widget (idle_dim_label);

        var screen_timeout_label = new Gtk.Label (_("Automatic Display Off")) {
            xalign = 0
        };

        var screen_timeout = new TimeoutComboBox (new GLib.Settings ("org.gnome.desktop.session"), "idle-delay") {
            hexpand = true
        };

        // FIXME: Virtual machines can only shutdown or do nothing. Tablets always suspend.
        powerbutton_dropdown = new Gtk.DropDown.from_strings ({
            _("Do nothing"),
            _("Suspend"),
            _("Ask to shutdown")
        }) {
            hexpand = true
        };

        var powerbutton_label = new Gtk.Label (_("Power Button Behavior")) {
            mnemonic_widget = powerbutton_dropdown,
            xalign = 0
        };

        var main_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12
        };
        main_grid.attach (idle_dim_label, 0, 3);
        main_grid.attach (idle_dim_switch, 1, 3);
        main_grid.attach (screen_timeout_label, 0, 4);
        main_grid.attach (screen_timeout, 1, 4);
        main_grid.attach (powerbutton_label, 0, 5);
        main_grid.attach (powerbutton_dropdown, 1, 5);

        var sleep_timeout_label = new Gtk.Label (_("Suspend When Inactive For")) {
            xalign = 0
        };

        var sleep_timeout = new TimeoutComboBox (settings, "sleep-inactive-ac-timeout") {
            enum_property = "sleep-inactive-ac-type",
            enum_never_value = PowerActionType.NOTHING,
            enum_normal_value = PowerActionType.SUSPEND,
            hexpand = true
        };

        var ac_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12
        };
        ac_grid.attach (sleep_timeout_label, 0, 0);
        ac_grid.attach (sleep_timeout, 1, 0);

        var power_mode_button = new PowerModeButton (false);

        if (PowerModeButton.successfully_initialized) {
            ac_grid.attach (power_mode_button, 0, 1, 2);
        }

        stack = new Gtk.Stack ();
        stack.add_titled (ac_grid, "ac", _("Plugged In"));

        var stack_switcher = new Gtk.StackSwitcher () {
            stack = stack
        };

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        if (size_group.get_widgets ().length () == 0) {
            var children = stack_switcher.observe_children ();
            for (var index = 0; index < children.get_n_items (); index++) {
                size_group.add_widget ((Gtk.ToggleButton) children.get_item (index));
            }
        }

        if (power_manager.batteries.n_items > 0) {
            var battery_timeout_label = new Gtk.Label (_("Suspend When Inactive For")) {
                xalign = 0
            };
            label_size.add_widget (battery_timeout_label);

            var battery_timeout = new TimeoutComboBox (settings, "sleep-inactive-battery-timeout") {
                enum_property = "sleep-inactive-battery-type",
                enum_never_value = PowerActionType.NOTHING,
                enum_normal_value = PowerActionType.SUSPEND,
                  hexpand = true
            };

            var battery_grid = new Gtk.Grid () {
                column_spacing = 12,
                row_spacing = 12
            };
            battery_grid.attach (battery_timeout_label, 0, 0);
            battery_grid.attach (battery_timeout, 1, 0);

            var battery_power_mode_button = new PowerModeButton (true);

            if (PowerModeButton.successfully_initialized) {
                battery_grid.attach (battery_power_mode_button, 0, 1, 2);
            }

            var auto_low_power_switch = new Gtk.Switch () {
                halign = END,
                valign = CENTER
            };
            settings.bind ("power-saver-profile-on-low-battery", auto_low_power_switch, "active", DEFAULT);

            var auto_low_power_label = new Granite.HeaderLabel (_("Automatically Save Power")) {
                hexpand = true,
                mnemonic_widget = auto_low_power_switch,
                secondary_text = _("Power Saver mode will be used when battery is low")
            };

            var auto_low_power_box = new Gtk.Box (HORIZONTAL, 12);
            auto_low_power_box.append (auto_low_power_label);
            auto_low_power_box.append (auto_low_power_switch);

            battery_grid.attach (auto_low_power_box, 0, 3, 2);

            stack.add_titled (battery_grid, "battery", _("On Battery"));

            var left_sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                hexpand = true,
                valign = Gtk.Align.CENTER
            };

            var right_sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                hexpand = true,
                valign = Gtk.Align.CENTER
            };

            var switcher_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                margin_top = 24,
                margin_bottom = 12
            };
            switcher_box.append (left_sep);
            switcher_box.append (stack_switcher);
            switcher_box.append (right_sep);

            main_grid.attach (switcher_box, 0, 8, 2);
        }

        main_grid.attach (stack, 0, 9, 2);

        box.append (main_grid);

        child = box;

        label_size.add_widget (sleep_timeout_label);
        label_size.add_widget (screen_timeout_label);
        label_size.add_widget (powerbutton_label);

        // hide stack switcher if we only have ac line
        stack_switcher.visible = stack.observe_children ().get_n_items () > 1;

        update_powerbutton_dropdown ();
        settings.changed["power-button-action"].connect (update_powerbutton_dropdown);

        settings.bind ("idle-dim", idle_dim_switch, "active", DEFAULT);

        powerbutton_dropdown.notify["selected"].connect (() => {
            int[] map = {0, 1, 3};
            settings.set_enum (
                "power-button-action",
                map[powerbutton_dropdown.selected]
            );
        });
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
     * In order to deliver smooth brightness changes it:
     * * accumulates very small changes until they become significant.
     * * ignores rapid changes in direction.
     * * responds to both horizontal and vertical scrolling.
     * In the case of diagonal scrolling, it ignores the event unless movement in one direction
     * is more than twice the movement in the other direction.
     */
     private bool handle_scroll_event (Gdk.ScrollEvent e, out double dir) {
        dir = 0.0;
        bool natural_scroll;
        var event_source = e.get_device ().get_source ();

        // If scroll is smooth it's probably a touchpad
        if (event_source == Gdk.InputSource.TOUCHPAD || e.get_direction () == Gdk.ScrollDirection.SMOOTH) {
            natural_scroll = natural_scroll_touchpad;
        } else if (event_source == Gdk.InputSource.MOUSE) {
            natural_scroll = natural_scroll_mouse;
        } else {
            natural_scroll = false;
        }

        switch (e.get_direction ()) {
            case Gdk.ScrollDirection.SMOOTH:
                double dx, dy;
                e.get_deltas (out dx, out dy);

                var abs_x = double.max (dx.abs (), 0.0001);
                var abs_y = double.max (dy.abs (), 0.0001);

                if (abs_y / abs_x > 2.0) {
                    total_y_delta += dy;
                } else if (abs_x / abs_y > 2.0) {
                    total_x_delta += dx;
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

        if (total_y_delta.abs () * BRIGHTNESS_STEP > 1.0) {
            dir = natural_scroll ? total_y_delta : -total_y_delta;
        } else if (total_x_delta.abs () * BRIGHTNESS_STEP > 1.0) {
            dir = natural_scroll ? -total_x_delta : total_x_delta;
        }

        if (dir.abs () > 0.0) {
            total_y_delta = 0.0;
            total_x_delta = 0.0;
            return true;
        }

        return false;
    }

    private void update_powerbutton_dropdown () {
        int[] map = {0, 1, 1, 2};
        powerbutton_dropdown.selected = map [settings.get_enum ("power-button-action")];
    }
}
