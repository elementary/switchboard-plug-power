/*
 * Copyright (c) 2011-2021 elementary, Inc. (https://elementary.io)
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
 public class Power.BatteryView : Granite.SimpleSettingsPage {
    private Battery battery;
    //  private Services.DeviceManager dm;

    public BatteryView (Gtk.Widget icon) {
        Object (
            header: _("Devices"),
            title: _("Built-in"),
            display_widget: icon,
            description: _("Rechargeable batteries naturally lose capacity over time and when used. To maximize battery health, avoid leaving your device connected to power after it is charged.")
        );
    }

    construct {
      battery = new Battery ();
      status = battery.get_info ();
      content_area.row_spacing = 6;
      content_area.margin_left = 50;
      content_area.margin_top = 20;

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
      var health = (int) Math.round (battery.capacity);
      var health_percent = new Gtk.Label (health.to_string () + "%") {
          halign = Gtk.Align.START,
          xalign = 1
      };

      var capacity_label = new Gtk.Label (_("Capacity:")) {
          halign = Gtk.Align.END,
          xalign = 1
      };
      var battery_capacity = (int) Math.round (battery.energy_full_design);
      var capacity = new Gtk.Label (battery_capacity.to_string () + " Wh") {
          halign = Gtk.Align.START,
          xalign = 1
      };

      content_area.attach (health_label, 0, 0);
      content_area.attach (health_percent, 1, 0);
      content_area.attach (charge_label, 0, 1);
      content_area.attach (charge_percent, 1, 1);
      content_area.attach (capacity_label, 0, 2);
      content_area.attach (capacity, 1, 2);
    }

}
