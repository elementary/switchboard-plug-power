/*
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
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

namespace Power {
    private GLib.Settings settings;

    public class Plug : Switchboard.Plug {
        private Gtk.Box box;
        private MainView main_view;

        public Plug () {
            GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
            GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");

            var supported_settings = new Gee.TreeMap<string, string?> (null, null);
            supported_settings["power"] = null;

            Object (category: Category.HARDWARE,
                code_name: "io.elementary.settings.power",
                display_name: _("Power"),
                description: _("Configure display brightness, power buttons, and suspend behavior"),
                icon: "preferences-system-power",
                supported_settings: supported_settings);
        }

        public override Gtk.Widget get_widget () {
            if (box == null) {
                Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).add_resource_path ("/io/elementary/settings/power");

                var headerbar = new Adw.HeaderBar () {
                    show_title = false
                };
                headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

                main_view = new MainView () {
                    vexpand = true
                };

                box = new Gtk.Box (VERTICAL, 0);
                box.append (headerbar);
                box.append (main_view);
            }

            return box;
        }

        public override void shown () {
            if (main_view.stack == null) {
                return;
            }

            if (PowerManager.get_default ().on_battery ()) {
                main_view.stack.visible_child_name = "battery";
            } else {
                main_view.stack.visible_child_name = "ac";
            }
        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
            search_results.set ("%s → %s".printf (display_name, _("Automatically Adjust Brightness")), "");
            search_results.set ("%s → %s".printf (display_name, _("Automatically Dim Display")), "");
            search_results.set ("%s → %s".printf (display_name, _("Automatically Save Power")), "");
            search_results.set ("%s → %s".printf (display_name, _("Automatic Display Off")), "");
            search_results.set ("%s → %s".printf (display_name, _("Battery Level")), "");
            search_results.set ("%s → %s".printf (display_name, _("Dim Display")), "");
            search_results.set ("%s → %s".printf (display_name, _("Display Brightness")), "");
            search_results.set ("%s → %s".printf (display_name, _("Lid Close Behavior")), "");
            search_results.set ("%s → %s".printf (display_name, _("Lid Close With External Display")), "");
            search_results.set ("%s → %s".printf (display_name, _("Power Button Behavior")), "");
            search_results.set ("%s → %s".printf (display_name, _("Suspend When Inactive For")), "");
            return search_results;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Power plug");
    var plug = new Power.Plug ();
    return plug;
}
