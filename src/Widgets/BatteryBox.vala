/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class Power.BatteryBox : Gtk.Grid {
    construct {
        var battery_header = new Granite.HeaderLabel ("");

        var devices_box = new Gtk.Box (HORIZONTAL, 24) {
            margin_bottom = 6
        };

        ulong n_batteries = 0;

        var devices = PowerManager.get_default ().devices;

        var has_battery = false;
        for (int i = 0; i < devices.n_items; i++) {
            var device = (Device) devices.get_item (i);
            if (device.device_type == BATTERY) {
                devices_box.append (new Battery (device));
                n_batteries ++;
            }
        }

        battery_header.label = ngettext (
            _("Battery Level"),
            _("Battery Levels"),
            n_batteries
        );

        var show_percent_switch = new Gtk.Switch () {
            halign = END
        };

        var show_percent_label = new Granite.HeaderLabel (_("Show Percentage In Panel")) {
            mnemonic_widget = show_percent_switch
        };

        var wingpanel_power_settings = new Settings ("io.elementary.desktop.wingpanel.power");
        wingpanel_power_settings.bind ("show-percentage", show_percent_switch, "active", DEFAULT);

        column_spacing = 12;
        row_spacing = 6;
        attach (battery_header, 0, 0, 2);
        attach (devices_box, 0, 1, 2);
        attach (show_percent_label, 0, 3);
        attach (show_percent_switch, 1, 3);
    }

    private class Battery : Gtk.Grid {
        public Device device { get; construct; }

        private Gtk.LevelBar charge_levelbar;

        public Battery (Device device) {
            Object (device: device);
        }

        construct {
            var charge_label = new Gtk.Label ("") {
                valign = BASELINE
            };
            charge_label.add_css_class (Granite.STYLE_CLASS_H1_LABEL);

            var cent_label = new Gtk.Label ("%") {
                halign = START,
                hexpand = true,
                valign = BASELINE
            };
            cent_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

            charge_levelbar = new Gtk.LevelBar.for_interval (0, 100) {
                hexpand = true
            };
            charge_levelbar.add_offset_value ("full", 100);

            var state_label = new Gtk.Label ("") {
                halign = START
            };
            state_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            row_spacing = 6;
            attach (charge_label, 0, 0);
            attach (cent_label, 1, 0);
            attach (charge_levelbar, 0, 2, 2);
            attach (state_label, 0, 3, 2);

            device.bind_property ("percentage", charge_levelbar, "value", SYNC_CREATE);

            device.bind_property ("percentage", charge_label, "label", SYNC_CREATE,
                ((binding, srcval, ref targetval) => {
                    targetval.set_string ("%.0f".printf ((double) srcval));
                    return true;
                })
            );

            device.bind_property ("state", state_label, "label", SYNC_CREATE,
                ((binding, srcval, ref targetval) => {
                    targetval.set_string (((Device.State) srcval).to_string ());
                    return true;
                })
            );

            update_levelbar_offsets ();
            device.notify["state"].connect (update_levelbar_offsets);
        }

        private void update_levelbar_offsets () {
            if (device.state == CHARGING || device.state == FULLY_CHARGED) {
                charge_levelbar.remove_offset_value ("high");
                charge_levelbar.remove_offset_value ("middle");
                charge_levelbar.remove_offset_value ("low");
            } else {
                charge_levelbar.add_offset_value ("high", 99);
                charge_levelbar.add_offset_value ("middle", 20);
                charge_levelbar.add_offset_value ("low", 10);
            }
        }
    }
}
