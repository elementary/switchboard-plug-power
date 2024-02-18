/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class Power.DevicesBox : Gtk.Grid {
    construct {
        var placeholder = new Gtk.Label (_("Devices that report battery information when plugged in or connected wirelessly will appear here")) {
            wrap = true,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        placeholder.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var devices_box = new Gtk.ListBox () {
            hexpand = true
        };
        devices_box.bind_model (
            PowerManager.get_default ().devices,
            create_widget_func
        );
        devices_box.set_placeholder (placeholder);
        devices_box.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        devices_box.add_css_class (Granite.STYLE_CLASS_FRAME);

        var header = new Granite.HeaderLabel (_("Connected Devices")) {
            mnemonic_widget = devices_box
        };

        column_spacing = 12;
        row_spacing = 6;
        attach (header, 0, 0, 2);
        attach (devices_box, 0, 1, 2);
    }

    private Gtk.Widget create_widget_func (Object object) {
        return new DeviceRow ((Device) object);
    }

    private class DeviceRow : Gtk.Grid {
        public Device device { get; construct; }

        private static Gtk.SizeGroup size_group;

        private Gtk.LevelBar charge_levelbar;

        public DeviceRow (Device device) {
            Object (device: device);
        }

        static construct {
            size_group = new Gtk.SizeGroup (HORIZONTAL);
        }

        construct {
            var image = new Gtk.Image.from_icon_name (device.icon_name) {
                icon_size = LARGE,
                use_fallback = true
            };

            var name_label = new Gtk.Label ("") {
                margin_end = 12,
                xalign = 0
            };

            var charge_label = new Gtk.Label ("") {
                xalign = 0
            };
            charge_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
            charge_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

            var charge_image = new Gtk.Image.from_gicon (device.state.to_icon ()) {
                tooltip_text = device.state.to_string ()
            };

            var charge_revealer = new Gtk.Revealer () {
                child = charge_image,
                transition_type = CROSSFADE,
                reveal_child = device.state.to_icon () != null
            };

            charge_levelbar = new Gtk.LevelBar () {
                hexpand = true,
                margin_end = 6,
                min_value = 0,
                valign = CENTER
            };

            if (!device.coarse_battery_level) {
                charge_levelbar.max_value = 100;
                charge_levelbar.add_offset_value ("full", 100);
                device.bind_property ("percentage", charge_levelbar, "value", SYNC_CREATE);
            } else {
                charge_levelbar.max_value = 5;
                charge_levelbar.mode = DISCRETE;

                // DeviceRow level is sometimes 0 so more reliable to divide percentage;
                device.bind_property ("percentage", charge_levelbar, "value", SYNC_CREATE,
                    ((binding, srcval, ref targetval) => {
                        targetval.set_double ((double) srcval / 20);
                        return true;
                    })
                );
            }

            column_spacing = 6;
            attach (image, 0, 0, 1, 2);
            attach (name_label, 1, 0);
            attach (charge_label, 1, 1);
            attach (charge_revealer, 2, 0, 1, 2);
            attach (charge_levelbar, 3, 0, 1, 2);

            size_group.add_widget (name_label);
            size_group.add_widget (charge_label);

            device.bind_property ("model", name_label, "label", SYNC_CREATE);
            device.bind_property ("description", charge_label, "label", SYNC_CREATE);

            update_levelbar_offsets ();
            device.notify["state"].connect (update_levelbar_offsets);

            device.notify["state"].connect (() => {
                charge_image.gicon = device.state.to_icon ();
                charge_image.tooltip_text = device.state.to_string ();
                charge_revealer.reveal_child = device.state.to_icon () != null;
            });
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
