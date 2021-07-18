/*
 * Copyright (c) 2011-2018 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: Subhadeep Jasu <subhajasu@gmail.com>
 */

namespace Power {
    public class PowerModeButton : Granite.Widgets.ModeButton {
        Gtk.Image power_saving_icon;
        Gtk.Image automatic_icon;
        Gtk.Image high_performance_icon;
        public PowerModeButton () {
            power_saving_icon = new Gtk.Image.from_icon_name ("battery-full-charged", Gtk.IconSize.DND);
            automatic_icon = new Gtk.Image.from_icon_name ("emblem-synchronized", Gtk.IconSize.DND);
            high_performance_icon = new Gtk.Image.from_icon_name ("preferences-system-power", Gtk.IconSize.DND);
            power_saving_icon.tooltip_text = _("Power Saving Mode");
            automatic_icon.tooltip_text = _("Automatic Mode");
            high_performance_icon.tooltip_text = _("High Performance Mode");
            append (power_saving_icon);
            append (automatic_icon);
            append (high_performance_icon);

            var default_schema = SettingsSchemaSource.get_default ();
            GLib.Settings power_daemon_settings = null;
            if (default_schema.lookup ("io.elementary.power-manager-daemon.powermode", false) != null) {
                power_daemon_settings = new GLib.Settings ("io.elementary.power-manager-daemon.powermode");
                this.selected = power_daemon_settings.get_int ("power-mode");
            }

            this.mode_changed.connect (() => {
                if (power_daemon_settings != null) {
                    power_daemon_settings.set_int ("power-mode", this.selected);
                }
            });
        }
    }
}
