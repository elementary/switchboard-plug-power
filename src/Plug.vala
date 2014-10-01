namespace Power {

	GLib.Settings settings;
	Gtk.Box stack_container;
	
	[DBus (name = "org.gnome.SettingsDaemon.Power.Screen")]

	interface PowerSettings : GLib.Object {
		public abstract uint GetPercentage () throws IOError;
		public abstract uint SetPercentage (uint percentage) throws IOError;
		// use the Brightness property after updateing g-s-d to 3.10 or above
		// public abstract int Brightness {get; set; }
	}

	[DBus (name = "org.freedesktop.UPower")]
	interface UPowerSettings : GLib.Object {
		public abstract string[] EnumerateDevices () throws IOError;
	}

	[DBus (name = "org.freedesktop.UPower.Device")]
	interface UPowerDevice : GLib.Object {
		public abstract uint Type {get; set;}
	}
	class ComboBox : Gtk.ComboBoxText {
	
		public Gtk.Label label;
		private string key;
		
		// this maps combobox indices to gsettings enums
		private int[] map_to_sett = {1, 2, 3, 4, 5};
		// and vice-versa
		private int[] map_to_list = {4, 0, 1, 2, 3, 4};
		
		public ComboBox (string label, string key) {
			this.key = key;
			this.label = new Gtk.Label (label);
			this.label.halign = Gtk.Align.END;
			this.label.xalign = 1.0f;

			this.append_text (_("Suspend"));
			this.append_text (_("Shutdown"));
			this.append_text (_("Hibernate"));
			this.append_text (_("Ask me"));
			this.append_text (_("Do nothing"));
		
			this.hexpand = true;
		
			update_combo ();
		
			this.changed.connect (update_settings);
			settings.changed[key].connect (update_combo);
		}

		private void update_settings () {
			settings.set_enum (key, map_to_sett[active]);
		}
	
		private void update_combo () {
			int val = settings.get_enum (key);
			active = map_to_list [val];
		}
	}
	
	public class Plug : Switchboard.Plug {
	
		private PowerSettings screen;
		private UPowerSettings upower;
		private Gtk.SizeGroup label_size;

		public Plug () {
			Object (category: Category.HARDWARE,
				code_name: "system-pantheon-power",
				display_name: _("Power"),
				description: _("Set display brightness, power button behavior, and sleep preferences"),
				icon: "preferences-system-power");

			settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
			try {
				screen = Bus.get_proxy_sync (BusType.SESSION,
								"org.gnome.SettingsDaemon",
								"/org/gnome/SettingsDaemon/Power");
			} catch (IOError e) {
				warning ("Failed to get settings daemon for brightness setting");
			}

			try {
				upower = Bus.get_proxy_sync (BusType.SYSTEM,
								"org.freedesktop.UPower",
								"/org/freedesktop/UPower");
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

			var plug_grid = create_notebook_pages ("ac");
			var common_settings = create_common_settings ();
			var stack = new Gtk.Stack ();
			var stack_switcher = new Gtk.StackSwitcher ();
			stack_switcher.halign = Gtk.Align.CENTER;
			stack_switcher.stack = stack;
			stack.add_titled (plug_grid, "ac", _("Plugged In"));

			if (detect_laptop () || have_ups ()) { // when its not laptop, we check for ups
				var battery_grid = create_notebook_pages ("battery");
				stack.add_titled (battery_grid, "battery", _("On Battery"));
			}

			stack_container.pack_start (common_settings);
			stack_container.pack_start (separator);
			stack_container.pack_start(stack_switcher, false, false, 0);
			stack_container.pack_start(stack, true, true, 0);
			stack_container.margin = 12;
			stack_container.show_all ();
		}

		private Gtk.Grid create_common_settings () {
			var grid = new Gtk.Grid ();
			grid.margin = 12;
			grid.column_spacing = 12;
			grid.row_spacing = 12;

			var brightness_label = new Gtk.Label (_("Display brightness:"));
			brightness_label.xalign = 1.0f;
			label_size.add_widget (brightness_label);
			brightness_label.halign = Gtk.Align.END;

			var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10);
			scale.set_draw_value (false);
			scale.hexpand = true;
			scale.width_request = 480;

			var dim_label = new Gtk.Label (_("Dim screen when inactive:"));
			dim_label.xalign = 1.0f;
			var dim_switch = new Gtk.Switch ();
			dim_switch.halign = Gtk.Align.START;

			settings.bind ("idle-dim", dim_switch, "active", SettingsBindFlags.DEFAULT);

			try {
				// scale.set_value (screen.Brightness);
				scale.set_value (screen.GetPercentage ());
			} catch (Error e) {
				warning ("Brightness setter not available, hiding brightness settings");
				brightness_label.no_show_all = true;
				scale.no_show_all = true;
				dim_label.no_show_all = true;
				dim_switch.no_show_all = true;
			}
			scale.value_changed.connect (() => {
				var val = (int) scale.get_value ();
				try {
					// screen.Brightness = val;
					screen.SetPercentage (val);
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
				var box = new Power.ComboBox (labels[i], keys[i]);
				grid.attach (box.label, 0, i+3, 1, 1);
				label_size.add_widget (box.label);
				grid.attach (box, 1, i+3, 1, 1);
			}
			
			return grid;
		}
	
		private Gtk.Grid create_notebook_pages (string type) {
			var grid = new Gtk.Grid ();
			grid.margin = 12;
			grid.column_spacing = 12;
			grid.row_spacing = 12;

			var scale_label = new Gtk.Label (_("Sleep when inactive after:"));
			scale_label.xalign = 1.0f;
			label_size.add_widget (scale_label);
			var scale_settings = @"sleep-inactive-$type-timeout";
			
			var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 4000, 300);
			scale.set_draw_value (false);
			scale.add_mark (300, Gtk.PositionType.BOTTOM, _("5 min"));
			scale.add_mark (600, Gtk.PositionType.BOTTOM, _("10 min"));
			scale.add_mark (1800, Gtk.PositionType.BOTTOM, _("30 min"));
			scale.add_mark (3600, Gtk.PositionType.BOTTOM, _("1 hour"));
			scale.add_mark (4000, Gtk.PositionType.BOTTOM, _("Never"));
			scale.hexpand = true;
			scale.width_request = 480;
		
			var dval = (double) settings.get_int (scale_settings);
		
			if (dval == 0)
				scale.set_value (4000);
			else
				scale.set_value (dval);
		
			scale.value_changed.connect (() => {
				var val = (int) scale.get_value ();
				if (val <= 3600)
					settings.set_int (scale_settings, val);
				else if (val == 4000)
					settings.set_int (scale_settings, 0);
			});
		
			grid.attach (scale_label, 0, 0, 1, 1);
			grid.attach (scale, 1, 0, 1, 1);
		
			if (type != "ac") {
				var critical_box = new ComboBox (_("When power is critically low:"), "critical-battery-action");
				grid.attach (critical_box.label, 0, 2, 1, 1);
				label_size.add_widget (critical_box.label);
				grid.attach (critical_box, 1, 2, 1, 1);
			}
			
			return grid;
		}

		private bool detect_laptop () {
			string test_laptop_detect = Environment.find_program_in_path("laptop-detect");
			if (test_laptop_detect != null) {
				int exit_status;
				string standard_output, standard_error;
				try {
					Process.spawn_command_line_sync ("laptop-detect", out standard_output,
																	out standard_error,
																	out exit_status);
					if (exit_status == 0) {
						debug ("Laptop detect return true");
						return true;
					}
					else {
						debug ("Laptop detect return false");
						return false;
					}
				}
				catch (SpawnError err) {
					warning (err.message);
					return false;
				}
			}
			else {
				warning ("Laptop detect not find");
				/* TODO check upower, and /proc files like laptop-detect to find bateries */
				return false;
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
		//TODO:check for ups using upower
		string[] devices;

		try {
			devices = upower.EnumerateDevices ();
		} catch (Error e) {
			message (e.message);
			return false;
		}

		foreach (var device in devices){
			try {
				UPowerDevice upower_device = Bus.get_proxy_sync (BusType.SYSTEM,
								"org.freedesktop.UPower",
								device);
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