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

namespace Power {
    private GLib.Settings settings;

    public class Plug : Switchboard.Plug {
        private Upower? upower = null;
        private string manufacturer_icon_path;
        public Gee.HashMap<string, Gtk.Widget> entries;

        private BehaviorView main_view;
        private DeviceView device_view;
        private Gtk.Stack stack;
        private Gtk.Paned hpaned;
        private Gtk.Grid main_grid;
        private Gtk.InfoBar infobar;
        private Gtk.LockButton lock_button;
        private SystemInterface system_interface;
        private Gtk.Image manufacturer_logo;

        construct {
            try {
                upower = Bus.get_proxy_sync (BusType.SYSTEM, DBUS_UPOWER_NAME, DBUS_UPOWER_PATH, DBusProxyFlags.NONE);
            } catch (Error e) {
                critical ("Connecting to UPower bus failed: %s", e.message);
            }
        }

        public Plug () {
            var supported_settings = new Gee.TreeMap<string, string?> (null, null);
            supported_settings["power"] = null;

            Object (category: Category.HARDWARE,
                code_name: "io.elementary.switchboard.power",
                display_name: _("Power"),
                description: _("Configure display brightness, power buttons, and suspend behavior"),
                icon: "preferences-system-power",
                supported_settings: supported_settings);
        }

        public override Gtk.Widget get_widget () {
            if (main_grid == null) {
                manufacturer_logo = new Gtk.Image () {
                    halign = Gtk.Align.END,
                    pixel_size = 32,
                    use_fallback = true
                };

                var fileicon = new FileIcon (File.new_for_path (manufacturer_icon_path));
                if (manufacturer_icon_path != null) {
                    manufacturer_logo.gicon = fileicon;
                }

                if (manufacturer_logo.gicon == null) {
                    load_fallback_manufacturer_icon.begin ();
                }

                stack = new Gtk.Stack ();
                main_view = new BehaviorView ();
                stack.add_named (main_view, "Power");

                if (main_view.battery.is_present ()) {
                    var badge_icon = new Gtk.Image.from_icon_name (main_view.battery.get_icon_name_for_battery (), Gtk.IconSize.BUTTON) {
                        halign = Gtk.Align.END,
                        valign = Gtk.Align.END
                    };

                    var overlay = new Gtk.Overlay ();
                    overlay.add (manufacturer_logo);
                    overlay.add_overlay (badge_icon);
                    device_view = new DeviceView (
                        main_view.battery.native_path,
                        overlay,
                        main_view.battery.get_info (),
                        "Built-in",
                        true
                    );
                    stack.add_named (device_view, "Built-in");
                }
                // TODO: add all other devices
                fetch_devices ();

                var switcher = new Granite.SettingsSidebar (stack);

                hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
                hpaned.pack1 (switcher, false, false);
                hpaned.add (stack);
                hpaned.show_all ();

                infobar = new Gtk.InfoBar ();
                infobar.message_type = Gtk.MessageType.INFO;

                lock_button = new Gtk.LockButton (get_permission ());

                var area = infobar.get_action_area () as Gtk.Container;
                area.add (lock_button);

                var content = infobar.get_content_area ();
                content.add (new Gtk.Label (_("Some settings require administrator rights to be changed")));

                var permission = get_permission ();
                permission.bind_property (
                    "allowed",
                    infobar,
                    "revealed",
                    GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN
                );

                main_grid = new Gtk.Grid () {
                    orientation = Gtk.Orientation.VERTICAL
                };
                main_grid.add (infobar);
                main_grid.add (hpaned);
                main_grid.show_all ();
            }

            return main_grid;
        }

        public void fetch_devices () {
            if (upower != null) {
                try {
                    var devices = upower.enumerate_devices ();
                    foreach (ObjectPath device_path in devices) {
                        if (device_with_battery (device_path) == true) {
                            var device_widget = get_device_row (device_path);
                            stack.add_named (device_widget, device_path);
                        }
                    }
                } catch (Error e) {
                    critical ("Reading UPower devices failed: %s", e.message);
                }
            }
        }

        private bool device_with_battery (string device_path) {
            var device = new Services.Device (device_path);
            //  devices.@set (device_path, device);
            return (device.is_a_battery && device.is_present () && device.device_type != Services.Device.Type.BATTERY);
        }

        public Gtk.Widget get_device_row (string device_path) {
            var device = new Services.Device (device_path);
            var device_icon = new Gtk.Image.from_icon_name (device.device_type.get_icon_name (), Gtk.IconSize.DND);
            var badge_icon = new Gtk.Image.from_icon_name (device.get_icon_name_for_battery (), Gtk.IconSize.BUTTON) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.END
            };
            var overlay = new Gtk.Overlay ();
            overlay.add (device_icon);
            overlay.add_overlay (badge_icon);
            var battery_view = new DeviceView (device_path, overlay, device.get_info (), device.device_type.get_name (), false);
            return battery_view;
        }

        public override void shown () {

        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
            search_results.set ("%s → %s".printf (display_name, _("Suspend button")), "");
            search_results.set ("%s → %s".printf (display_name, _("Power button")), "");
            search_results.set ("%s → %s".printf (display_name, _("Display inactive")), "");
            search_results.set ("%s → %s".printf (display_name, _("Dim display")), "");
            search_results.set ("%s → %s".printf (display_name, _("Lid close")), "");
            search_results.set ("%s → %s".printf (display_name, _("Display brightness")), "");
            search_results.set ("%s → %s".printf (display_name, _("Automatic brightness adjustment")), "");
            search_results.set ("%s → %s".printf (display_name, _("Inactive display off")), "");
            search_results.set ("%s → %s".printf (display_name, _("Docked lid close")), "");
            search_results.set ("%s → %s".printf (display_name, _("Sleep inactivity timeout")), "");
            search_results.set ("%s → %s".printf (display_name, _("Suspend inactive")), "");
            return search_results;
        }

        public async void load_fallback_manufacturer_icon () {
            try {
                system_interface = yield Bus.get_proxy (
                    BusType.SYSTEM,
                    "org.freedesktop.hostname1",
                    "/org/freedesktop/hostname1"
                );

                manufacturer_logo.icon_name = system_interface.icon_name;
            } catch (IOError e) {
                critical (e.message);
            }
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Power plug");
    var plug = new Power.Plug ();
    return plug;
}

[DBus (name = "org.freedesktop.hostname1")]
public interface SystemInterface : Object {
    [DBus (name = "IconName")]
    public abstract string icon_name { owned get; }
}
