/*
 *  Copyright (C)  2015 Pantheon Developers (http://launchpad.net/switchboard-plug-power)
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 */

namespace Power {

    GLib.Settings settings;
    Gtk.Box stack_container;

    [DBus (name = "org.gnome.SettingsDaemon.Power.Screen")]
    interface PowerSettings : GLib.Object {
#if OLD_GSD
        public abstract uint GetPercentage () throws IOError;
        public abstract uint SetPercentage (uint percentage) throws IOError;
#else
        // use the Brightness property after updateing g-s-d to 3.10 or above
        public abstract int Brightness {get; set; }
#endif
    }

    [DBus (name = "org.freedesktop.UPower")]
    interface UPower : GLib.Object {
        public abstract string[] EnumerateDevices () throws IOError;
    }

    [DBus (name = "org.freedesktop.UPower.Device")]
    interface UPowerDevice : GLib.Object {
        public abstract uint Type {get; set;}
    }

    public class Plug : Switchboard.Plug {

        private PowerSettings screen;
        private UPower upower;
        private Gtk.SizeGroup label_size;
        private GLib.Settings pantheon_dpms_settings;

        public Plug () {
            Object (category: Category.HARDWARE,
                code_name: "system-pantheon-power",
                display_name: _("Power"),
                description: _("Set display brightness, power button behavior, and sleep preferences"),
                icon: "preferences-system-power");

            settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
            pantheon_dpms_settings = new GLib.Settings ("org.pantheon.dpms");
            try {
                screen = Bus.get_proxy_sync (BusType.SESSION,
                    "org.gnome.SettingsDaemon", "/org/gnome/SettingsDaemon/Power");
            } catch (IOError e) {
                warning ("Failed to get settings daemon for brightness setting");
            }

            try {
                upower = Bus.get_proxy_sync (BusType.SYSTEM,
                    "org.freedesktop.UPower", "/org/freedesktop/UPower");
            } catch (IOError e) {
                warning ("Failed to get settings daemon for brightness setting");
            }
        }

        public override Gtk.Widget get_widget () {
            if (stack_container == null) {
                //setup_info ();
                setup_ui ();
            }
            return stack_container;
        }

        public override void shown () {

        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            return new Gee.TreeMap<string, string> (null, null);
        }

        void setup_ui () {
            stack_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            label_size = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.vexpand = true;
            separator.valign = Gtk.Align.START;

            var common_settings = create_common_settings ();
            var stack = new Gtk.Stack ();
            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.halign = Gtk.Align.CENTER;
            stack_switcher.stack = stack;

            var plug_grid = create_notebook_pages ("ac");
            stack.add_titled (plug_grid, "ac", _("Plugged In"));

            if (laptop_detect () || have_ups ()) { // when its not laptop, we check for ups
                var battery_grid = create_notebook_pages ("battery");
                stack.add_titled (battery_grid, "battery", _("On Battery"));
            }

            stack_container.pack_start (common_settings);
            stack_container.pack_start (separator);
            stack_container.pack_start(stack_switcher, false, false, 0);
            stack_container.pack_start(stack, true, true, 0);
            stack_container.margin = 12;
            stack_container.show_all ();

            // hide stack switcher we only have ac line
            stack_switcher.set_visible (stack.get_children ().length () > 1);
            separator.set_visible (stack.get_children ().length () > 1);
        }

        private Gtk.Grid create_common_settings () {
            var grid = new Gtk.Grid ();
            grid.margin = 12;
            grid.column_spacing = 12;
            grid.row_spacing = 12;

            var brightness_label = new Gtk.Label (_("Display brightness:"));
            ((Gtk.Misc) brightness_label).xalign = 1.0f;
            label_size.add_widget (brightness_label);
            brightness_label.halign = Gtk.Align.END;

            var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10);
            scale.set_draw_value (false);
            scale.hexpand = true;
            scale.width_request = 480;

            var dim_label = new Gtk.Label (_("Dim screen when inactive:"));
            ((Gtk.Misc) dim_label).xalign = 1.0f;
            var dim_switch = new Gtk.Switch ();
            dim_switch.halign = Gtk.Align.START;

            settings.bind ("idle-dim", dim_switch, "active", SettingsBindFlags.DEFAULT);

            // Checking if device is a laptop or desktop. If it's a desktop, hide the brightness scale
            // Prevents plug freezing on desktops.
            bool show_brightness = false;
            try {
                var power_devices = upower.EnumerateDevices ();
                foreach (string device in power_devices) {
                    if (device.contains ("battery")) {
                        show_brightness = true;
                    }
                }

                if (show_brightness) {
#if OLD_GSD
                    scale.set_value (screen.GetPercentage ());
#else
                    scale.set_value (screen.Brightness);
#endif
                } else {
                    warning ("No battery found, hiding brightness settings");
                }

            } catch (Error e) {
                warning ("Brightness setter not available, hiding brightness settings");
                show_brightness = false;
            }

            if (show_brightness == false) {
                brightness_label.no_show_all = true;
                scale.no_show_all = true;
                dim_label.no_show_all = true;
                dim_switch.no_show_all = true;
            }

            scale.value_changed.connect (() => {
                var val = (int) scale.get_value ();
                try {
#if OLD_GSD
                    screen.SetPercentage (val);
#else
                    screen.Brightness = val;
#endif
                } catch (IOError ioe) {
                    // ignore, because if we have GetPercentage, we have SetPercentage
                    // otherwise the scale won't be visible to change
                }
            });

            grid.attach (brightness_label, 0, 1, 1, 1);
            grid.attach (scale, 1, 1, 1, 1);

            grid.attach (dim_label, 0, 2, 1, 1);
            grid.attach (dim_switch, 1, 2, 1, 1);

            string[] labels = {_("Sleep button:"), _("Suspend button:"), _("Hibernate button:"), _("Power button:")};
            string[] keys = {"button-sleep", "button-suspend", "button-hibernate", "button-power"};

            for (int i = 0; i < labels.length; i++) {
                var box = new ActionComboBox (labels[i], keys[i]);
                grid.attach (box.label, 0, i+3, 1, 1);
                label_size.add_widget (box.label);
                grid.attach (box, 1, i+3, 1, 1);
            }

            var screen_timeout_label = new Gtk.Label (_("Turn off screen when inactive after:"));
            label_size.add_widget (screen_timeout_label);
            ((Gtk.Misc) screen_timeout_label).xalign = 1.0f;
            var screen_timeout = new TimeoutComboBox (pantheon_dpms_settings, "standby-time");
            screen_timeout.changed.connect (run_dpms_helper);

            grid.attach (screen_timeout_label, 0, labels.length+3, 1, 1);
            grid.attach (screen_timeout, 1, labels.length+3, 1, 1);

            return grid;
        }

        private Gtk.Grid create_notebook_pages (string type) {
            var grid = new Gtk.Grid ();
            grid.margin = 12;
            grid.column_spacing = 12;
            grid.row_spacing = 12;

            var sleep_timeout_label = new Gtk.Label (_("Sleep when inactive after:"));
            ((Gtk.Misc) sleep_timeout_label).xalign = 1.0f;
            label_size.add_widget (sleep_timeout_label);

            var scale_settings = @"sleep-inactive-$type-timeout";
            var sleep_timeout = new TimeoutComboBox (settings, scale_settings);

            grid.attach (sleep_timeout_label, 0, 0, 1, 1);
            grid.attach (sleep_timeout, 1, 0, 1, 1);

            if (type != "ac") {
                var critical_box = new ActionComboBox (_("When power is critically low:"), "critical-battery-action");
                grid.attach (critical_box.label, 0, 2, 1, 1);
                label_size.add_widget (critical_box.label);
                grid.attach (critical_box, 1, 2, 1, 1);
            }

            return grid;
        }

        private bool laptop_detect () {
            string test_laptop_detect = Environment.find_program_in_path ("laptop-detect");
            if (test_laptop_detect == null && 
                FileUtils.test ("/usr/sbin/laptop-detect", FileTest.EXISTS) &&
                FileUtils.test ("/usr/sbin/laptop-detect", FileTest.IS_REGULAR) &&
                FileUtils.test ("/usr/sbin/laptop-detect", FileTest.IS_EXECUTABLE)) {
                test_laptop_detect = "/usr/sbin/laptop-detect";
            }

            if (test_laptop_detect != null) {
                int exit_status;
                string standard_output, standard_error;
                try {
                    Process.spawn_command_line_sync (test_laptop_detect, out standard_output,
                        out standard_error, out exit_status);
                    if (exit_status == 0) {
                        debug ("Laptop detect return true");
                        return true;
                    } else {
                        debug ("Laptop detect return false");
                        return false;
                    }
                } catch (SpawnError err) {
                    warning (err.message);
                    return false;
                }
            } else {
                warning ("Laptop detect not find");
                /* TODO check upower, and /proc files as laptop-detect does to find batteries */
                return false;
            }
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

    enum Type {
        UNKNOWN = 0,
        LINE_POWER,
        BATTERY,
        UPS,
        MONITOR,
        MOUSE,
        KEYBOARD,
        PDA
    }

    private bool have_ups () {
        /* TODO:check for ups using upower */
        string[] devices;

        try {
            devices = upower.EnumerateDevices ();
        } catch (Error e) {
            message (e.message);
            return false;
        }

        foreach (var device in devices) {
            try {
                UPowerDevice upower_device = Bus.get_proxy_sync (BusType.SYSTEM,
                    "org.freedesktop.UPower", device);
                if (upower_device.Type == Type.UPS) {
                    debug ("found UPS in %s", device);
                    return true;
                }
            } catch (Error e) {
                debug (e.message);
            }
        }

        return false;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Power plug");
    var plug = new Power.Plug ();
    return plug;
}