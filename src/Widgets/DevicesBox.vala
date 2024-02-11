/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class Power.DevicesBox : Gtk.Grid {
    construct {
        var header = new Granite.HeaderLabel (_("Connected Devices"));

        var devices_box = new Gtk.ListBox () {
            hexpand = true
        };
        devices_box.bind_model (
            PowerManager.get_default ().devices,
            create_widget_func
        );
        devices_box.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        devices_box.add_css_class (Granite.STYLE_CLASS_FRAME);

        column_spacing = 12;
        row_spacing = 6;
        attach (header, 0, 0, 2);
        attach (devices_box, 0, 1, 2);
    }

    private Gtk.Widget create_widget_func (Object object) {
        var battery = new Battery ((Device) object);

        if (battery.device.is_power_supply) {
            battery.visible = false;
        }

        return battery;
    }

    private class Battery : Gtk.Grid {
        public Device device { get; construct; }

        private static Gtk.SizeGroup size_group;

        private Gtk.LevelBar charge_levelbar;

        public Battery (Device device) {
            Object (device: device);
        }

        static construct {
            size_group = new Gtk.SizeGroup (HORIZONTAL);
        }

        construct {
            var image = new Gtk.Image.from_icon_name (device.device_type.to_icon_name ()) {
                icon_size = LARGE
            };

            var name_label = new Gtk.Label ("") {
                xalign = 0
            };

            var charge_label = new Gtk.Label ("") {
                xalign = 0
            };
            charge_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
            charge_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

            charge_levelbar = new Gtk.LevelBar () {
                hexpand = true,
                margin_start = 18,
                min_value = 0,
                valign = CENTER
            };

            if (device.battery_level == 1) {
                charge_levelbar.max_value = 100;
                charge_levelbar.add_offset_value ("full", 100);
                device.bind_property ("percentage", charge_levelbar, "value", SYNC_CREATE);
            } else {
                charge_levelbar.max_value = 5;
                charge_levelbar.mode = DISCRETE;

                // Battery level is sometimes 0 so more reliable to divide percentage;
                device.bind_property ("percentage", charge_levelbar, "value", SYNC_CREATE,
                    ((binding, srcval, ref targetval) => {
                        targetval.set_double ((double) srcval / 20);
                        return true;
                    })
                );
            }

            column_spacing = 6;
            row_spacing = 6;
            attach (image, 0, 0, 1, 2);
            attach (name_label, 1, 0);
            attach (charge_label, 1, 1);
            attach (charge_levelbar, 2, 0, 1, 2);

            size_group.add_widget (name_label);
            size_group.add_widget (charge_label);

            device.bind_property ("model", name_label, "label", SYNC_CREATE);

            if (charge_levelbar.mode == CONTINUOUS) {
                device.bind_property ("percentage", charge_label, "label", SYNC_CREATE,
                    ((binding, srcval, ref targetval) => {
                        targetval.set_string ("%.0f%%".printf ((double) srcval));
                        return true;
                    })
                );
            } else {
                charge_label.label = device.cent_to_string ();
                device.notify["percentage"].connect (() => {
                    charge_label.label = device.cent_to_string ();
                });
            }

            update_levelbar_offsets ();
            device.notify["state"].connect (update_levelbar_offsets);
        }

        private void update_levelbar_offsets () {
            if (device.state == CHARGING || device.state == FULLY_CHARGED) {
                charge_levelbar.remove_offset_value ("high");
                charge_levelbar.remove_offset_value ("middle");
                charge_levelbar.remove_offset_value ("low");
            } else {
                if (charge_levelbar.mode == CONTINUOUS) {
                    charge_levelbar.add_offset_value ("high", 99);
                    charge_levelbar.add_offset_value ("middle", 20);
                    charge_levelbar.add_offset_value ("low", 10);
                } else {
                    charge_levelbar.add_offset_value ("high", 3);
                    charge_levelbar.add_offset_value ("middle", 2);
                    charge_levelbar.add_offset_value ("low", 1);
                }

            }
        }
    }
}
