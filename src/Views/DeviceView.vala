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

public class Power.DeviceView : Granite.SimpleSettingsPage {

    public Services.Device battery { get; construct; default = null; }
    public string device_path { get; construct; default = ""; }

    public DeviceView (
        Services.Device device,
        Gtk.Widget icon,
        string status_device,
        string title,
        bool show_header
    ) {
        Object (
            header: show_header ? _("Devices") : null,
            title: title,
            display_widget: icon,
            description: "",
            status: status_device,
            battery: device
        );
    }

    construct {
        content_area.column_spacing = 6;
        content_area.row_spacing = 6;
        content_area.halign = Gtk.Align.CENTER;
        content_area.expand = true;

        if (battery.is_rechargeable) {
            description = _("Rechargeable batteries naturally lose capacity over time and when used.\nTo maximize battery health, avoid leaving your device connected to power after it is charged.");
        } else {
            description = _("Non-reachargeable battery.");
        }

        var charge_label = new Gtk.Label (_("Current charge:")) {
            halign = Gtk.Align.END,
            xalign = 1
        };

        var charge_percent = new Gtk.Label (battery.percentage.to_string () + "%") {
            halign = Gtk.Align.START,
            xalign = 1
        };

        var health_label = new Gtk.Label (_("Health:")) {
            halign = Gtk.Align.END,
            xalign = 1
        };

        var health = new Gtk.Label (battery.get_health ()) {
            halign = Gtk.Align.START,
            xalign = 1
        };

        var max_capacity_label = new Gtk.Label (_("Maximum capacity:")) {
            halign = Gtk.Align.END,
            xalign = 1
        };

        var max_capacity_number = (int) Math.round (battery.capacity);
        var max_capacity = new Gtk.Label (max_capacity_number.to_string () + "%") {
            halign = Gtk.Align.START,
            xalign = 1
        };

        var capacity_label = new Gtk.Label (_("Design energy:")) {
            halign = Gtk.Align.END,
            xalign = 1
        };

        var battery_capacity = (int) Math.round (battery.energy_full_design);
        var capacity = new Gtk.Label (battery_capacity.to_string () + " Wh") {
            halign = Gtk.Align.START,
            xalign = 1
        };

        if (battery.capacity != 0) {
            content_area.attach (health_label, 0, 0);
            content_area.attach (health, 1, 0);
            content_area.attach (capacity_label, 0, 3);
            content_area.attach (capacity, 1, 3);
            content_area.attach (max_capacity_label, 0, 1);
            content_area.attach (max_capacity, 1, 1);
        }

        content_area.attach (charge_label, 0, 2);
        content_area.attach (charge_percent, 1, 2);
    }

}
