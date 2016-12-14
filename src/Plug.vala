/*
 * Copyright (c) 2011-2016 elementary LLC. (https://launchpad.net/switchboard-plug-power)
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
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

namespace Power {

    GLib.Settings settings;
    Gtk.Grid stack_container;
    Gtk.Grid main_grid;

    public class Plug : Switchboard.Plug {
        private Gtk.SizeGroup label_size;
        private Gtk.StackSwitcher stack_switcher;
        private GLib.Settings pantheon_dpms_settings;

        private PowerSettings screen;
        private Battery battery;
        private PowerSupply power_supply;
        private CliCommunicator cli_communicator;
        private Gtk.Image lock_image;
        private Gtk.Image lock_image2;
        private Gtk.Scale scale;

        private const string NO_PERMISSION_STRING  = _("You do not have permission to change this");
        private const string LAPTOP_DETECT_BINARY = "/usr/sbin/laptop-detect";

        public Plug () {
            var switchboard_settings = new Gee.TreeMap<string, string?> (null, null);
            switchboard_settings.set ("power", "null");
            Object (category: Category.HARDWARE,
                code_name: "system-pantheon-power",
                display_name: _("Power"),
                description: _("Configure display brightness, power buttons, and sleep behavior"),
                icon: "preferences-system-power",
                supported_settings: switchboard_settings);

            settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
            pantheon_dpms_settings = new GLib.Settings ("org.pantheon.dpms");
            battery = new Battery ();
            power_supply = new PowerSupply ();
            cli_communicator = new CliCommunicator ();
            connect_dbus ();
        }

        public override Gtk.Widget get_widget () {
            if (stack_container == null) {
                setup_ui ();
            }

            return stack_container;
        }

        public override void shown () {
            if (battery.check_present ()) {
                stack_switcher.get_stack ().visible_child_name = "battery";
            } else {
                stack_switcher.get_stack ().visible_child_name = "ac";
            }
        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
            search_results.set ("%s → %s".printf (display_name, _("Sleep button")), "");
            search_results.set ("%s → %s".printf (display_name, _("Power button")), "");
            search_results.set ("%s → %s".printf (display_name, _("Display inactive")), "");
            search_results.set ("%s → %s".printf (display_name, _("Dim display")), "");
            search_results.set ("%s → %s".printf (display_name, _("Lid close")), "");
            search_results.set ("%s → %s".printf (display_name, _("Display brightness")), "");
            search_results.set ("%s → %s".printf (display_name, _("Automatic brightness adjustment")), "");
            search_results.set ("%s → %s".printf (display_name, _("Inactive display off")), "");
            search_results.set ("%s → %s".printf (display_name, _("Docked lid close")), "");
            search_results.set ("%s → %s".printf (display_name, _("Sleep inactive")), "");
            return search_results;;
        }

        private void setup_ui () {
            stack_container = new Gtk.Grid ();
            stack_container.orientation = Gtk.Orientation.VERTICAL;

            label_size = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

            Gtk.Grid info_bars = create_info_bars ();

            main_grid = new Gtk.Grid ();
            main_grid.margin = 24;
            main_grid.column_spacing = 12;
            main_grid.row_spacing = 12;

            create_common_settings ();

            Gtk.Stack stack = new Gtk.Stack ();

            Gtk.Grid plug_grid = create_notebook_pages (true);
            stack.add_titled (plug_grid, "ac", _("Plugged In"));

            stack_container.add (info_bars);

            stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.stack = stack;

            if (laptop_detect () || battery.laptop) {
                Gtk.Grid battery_grid = create_notebook_pages (false);
                stack.add_titled (battery_grid, "battery", _("On Battery"));

                var left_sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
                left_sep.hexpand = true;    

                var right_sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
                right_sep.hexpand = true;

                var switcher_grid = new Gtk.Grid ();
                switcher_grid.margin_top = 24;
                switcher_grid.margin_bottom = 12;
                switcher_grid.add (left_sep);
                switcher_grid.add (stack_switcher);
                switcher_grid.add (right_sep);

                main_grid.attach (switcher_grid, 0, 7, 2, 1);
            }

            main_grid.attach (stack, 0, 8, 2, 1);
            stack_container.add (main_grid);

            stack_container.margin_bottom = 12;
            stack_container.show_all ();

            // hide stack switcher if we only have ac line
            stack_switcher.visible = stack.get_children ().length () > 1;
        }

        private void connect_dbus () {
            try {
                screen = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.SettingsDaemon",
                    "/org/gnome/SettingsDaemon/Power", DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
            } catch (IOError e) {
                warning ("Failed to get settings daemon for brightness setting");
            }
        }

        private Gtk.Grid create_info_bars () {
            Gtk.Grid info_grid = new Gtk.Grid ();
            info_grid.column_homogeneous = true;

            Gtk.InfoBar infobar = new Gtk.InfoBar ();
            infobar.message_type = Gtk.MessageType.WARNING;
            infobar.no_show_all = true;
            var content = infobar.get_content_area () as Gtk.Container;
            Gtk.Label label = new Gtk.Label (_("Some changes will not take effect until you restart this computer"));
            content.add (label);
            infobar.hide ();

            cli_communicator.changed.connect (() => {
                infobar.no_show_all = false;
                infobar.show_all();

            });

            Gtk.InfoBar permission_infobar = new Gtk.InfoBar ();
            permission_infobar.message_type = Gtk.MessageType.INFO;

            var area_infobar = permission_infobar.get_action_area () as Gtk.Container;
            var lock_button = new Gtk.LockButton (get_permission ());
            area_infobar.add (lock_button);

            var content_infobar = permission_infobar.get_content_area () as Gtk.Container;
            Gtk.Label label_infobar = new Gtk.Label (_("Some settings require administrator rights to be changed"));
            content_infobar.add (label_infobar);

            if (laptop_detect () || battery.laptop) {
                permission_infobar.show_all ();
            } else {
                permission_infobar.no_show_all = true;
                permission_infobar.hide ();
            }

            //connect polkit permission to hiding the permission infobar
            get_permission ().notify["allowed"].connect (() => {
                if (get_permission ().allowed) {
                    permission_infobar.no_show_all = true;
                    permission_infobar.hide ();
                }
            });

            info_grid.attach (infobar, 0, 0, 1, 1);
            info_grid.attach (permission_infobar, 0, 1, 1, 1);

            return info_grid;
        }

        private Gtk.Grid create_common_settings () {
            lock_image = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            lock_image.tooltip_text = NO_PERMISSION_STRING;
            lock_image.sensitive = false;
            lock_image2 = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            lock_image2.tooltip_text = NO_PERMISSION_STRING;
            lock_image2.sensitive = false;

            if (laptop_detect () || battery.laptop) {
                var brightness_label = new Gtk.Label (_("Display brightness:"));
                ((Gtk.Misc) brightness_label).xalign = 1.0f;
                label_size.add_widget (brightness_label);
                brightness_label.halign = Gtk.Align.END;

                var als_label = new Gtk.Label (_("Automatically adjust brightness:"));
                ((Gtk.Misc) als_label).xalign = 1.0f;
                label_size.add_widget (als_label);
                var als_switch = new Gtk.Switch ();
                als_switch.halign = Gtk.Align.START;

                settings.bind ("ambient-enabled", als_switch, "active", SettingsBindFlags.DEFAULT);

                scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10);
                scale.draw_value = false;
                scale.hexpand = true;
                scale.width_request = 480;

                scale.set_value (screen.Brightness);

                scale.value_changed.connect (on_scale_value_changed);
                (screen as DBusProxy).g_properties_changed.connect (on_screen_properties_changed);

                var lid_closed_box = new LidCloseActionComboBox (_("When lid is closed:"), cli_communicator);
                lid_closed_box.sensitive = false;
                lid_closed_box.label.sensitive = false;
                label_size.add_widget (lid_closed_box.label);

                var lid_dock_box = new LidCloseActionComboBox (_("When lid is closed with external monitor:"), cli_communicator);
                lid_dock_box.sensitive = false;
                lid_dock_box.label.sensitive = false;
                label_size.add_widget (lid_dock_box.label);

                // lock and UI visible that settings are locked and unlocked
                get_permission ().notify["allowed"].connect (() => {
                    if (get_permission ().allowed) {
                        lid_closed_box.sensitive = true;
                        lid_closed_box.label.sensitive = true;
                        lid_dock_box.sensitive = true;
                        lid_dock_box.label.sensitive = true;
                        lock_image.visible = false;
                        lock_image2.visible = false;
                    } else {
                        lid_closed_box.sensitive = false;
                        lid_closed_box.label.sensitive = false;
                        lid_dock_box.sensitive = false;
                        lid_dock_box.label.sensitive = false;
                        lock_image.visible = true;
                        lock_image2.visible = true;
                    }
                });

                main_grid.attach (brightness_label, 0, 0, 1, 1);
                main_grid.attach (scale, 1, 0, 1, 1);
                main_grid.attach (als_label, 0, 1, 1, 1);
                main_grid.attach (als_switch, 1, 1, 1, 1);
                main_grid.attach (lid_closed_box.label, 0, 5, 1, 1);
                main_grid.attach (lid_closed_box, 1, 5, 1, 1);
                main_grid.attach (lock_image2, 2, 5, 1, 1);
                main_grid.attach (lid_dock_box.label, 0, 6, 1, 1);
                main_grid.attach (lid_dock_box, 1, 6, 1, 1);
                main_grid.attach (lock_image, 2, 6, 1, 1);
            }

            var screen_timeout_label = new Gtk.Label (_("Turn off display when inactive for:"));
            screen_timeout_label.halign = Gtk.Align.END;
            screen_timeout_label.xalign = 1.0f;
            label_size.add_widget (screen_timeout_label);

            var screen_timeout = new TimeoutComboBox (pantheon_dpms_settings, "standby-time");
            screen_timeout.changed.connect (run_dpms_helper);

            var power_combobox = new ActionComboBox (_("Power button:"), "power-button-action");
            label_size.add_widget (power_combobox.label);

            main_grid.attach (screen_timeout_label, 0, 3, 1, 1);
            main_grid.attach (screen_timeout, 1, 3, 1, 1);
            main_grid.attach (power_combobox.label, 0, 4, 1, 1);
            main_grid.attach (power_combobox, 1, 4, 1, 1);

            return main_grid;
        }
        
        private void on_scale_value_changed () {
            var val = (int) scale.get_value ();
            (screen as DBusProxy).g_properties_changed.disconnect (on_screen_properties_changed);
            screen.Brightness = val;
            (screen as DBusProxy).g_properties_changed.connect (on_screen_properties_changed);
        }
        
        private void on_screen_properties_changed (Variant changed_properties, string[] invalidated_properties) {
            var changed_brightness = changed_properties.lookup_value("Brightness", new VariantType("i"));
            if (changed_brightness != null) {
                var val = screen.Brightness;
                scale.value_changed.disconnect (on_scale_value_changed);
                scale.set_value (val);
                scale.value_changed.connect (on_scale_value_changed);
            }
        }

        private Gtk.Grid create_notebook_pages (bool ac) {
            var grid = new Gtk.Grid ();
            grid.column_spacing = 12;
            grid.row_spacing = 12;

            var sleep_timeout_label = new Gtk.Label (_("Suspend when inactive for:"));
            ((Gtk.Misc) sleep_timeout_label).xalign = 1.0f;
            label_size.add_widget (sleep_timeout_label);

            string type = "battery";
            if (ac) {
                type = "ac";
            }

            var scale_settings = @"sleep-inactive-$type-timeout";
            var sleep_timeout = new TimeoutComboBox (settings, scale_settings);

            grid.attach (sleep_timeout_label, 0, 1, 1, 1);
            grid.attach (sleep_timeout, 1, 1, 1, 1);

            if (!ac) {
                var dim_label = new Gtk.Label (_("Dim display when inactive:"));
                ((Gtk.Misc) dim_label).xalign = 1.0f;
                label_size.add_widget (dim_label);
                var dim_switch = new Gtk.Switch ();
                dim_switch.halign = Gtk.Align.START;

                settings.bind ("idle-dim", dim_switch, "active", SettingsBindFlags.DEFAULT);

                grid.attach (dim_label, 0, 0, 1, 1);
                grid.attach (dim_switch, 1, 0, 1, 1);

            } else if (battery.laptop) {

            }

            return grid;
        }

        private bool laptop_detect () {
            string? laptop_detect_executable = Environment.find_program_in_path ("laptop-detect");
            if (laptop_detect_executable == null || 
                !FileUtils.test (laptop_detect_executable, FileTest.IS_EXECUTABLE) ||
                !FileUtils.test (LAPTOP_DETECT_BINARY, FileTest.IS_EXECUTABLE)) {
                warning ("Laptop detect not found");
                return false;
            }

            int exit_status;
            string standard_output, standard_error;
            try {
                Process.spawn_command_line_sync (laptop_detect_executable, out standard_output,
                    out standard_error, out exit_status);
                if (exit_status == 0) {
                    debug ("Laptop detect returned true");
                    return true;
                }
            } catch (SpawnError err) {
                warning (err.message);
                return false;
            }

            debug ("Laptop detect returned false");
            return false;
        }

        private void run_dpms_helper () {
            Settings.sync ();

            try {
                Process.spawn_async (null, { "elementary-dpms-helper" }, Environ.get (),
                    SpawnFlags.SEARCH_PATH|SpawnFlags.STDERR_TO_DEV_NULL|SpawnFlags.STDOUT_TO_DEV_NULL,
                    null, null);
            } catch (SpawnError e) {
                warning ("Failed to reset dpms settings: %s", e.message);
            }
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Power plug");
    var plug = new Power.Plug ();
    return plug;
}
