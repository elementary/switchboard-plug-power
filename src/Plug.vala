namespace Power {

	GLib.Settings settings;
	Gtk.Box stack_container;
	
	[DBus (name = "org.gnome.SettingsDaemon.Power.Screen")]
 
	interface PowerSettings : GLib.Object {
        public abstract int Brightness {get; set; }
		public signal void Changed ();
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
		private Gtk.SizeGroup label_size;

		public Plug () {
			Object (category: Category.HARDWARE,
				code_name: "system-pantheon-power",
				display_name: _("Power"),
				description: _("Shows Power Settings…"),
				icon: "preferences-system-power");

			settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
            try {
				screen = Bus.get_proxy_sync (BusType.SESSION,
                                             "org.gnome.SettingsDaemon",
                                             "/org/gnome/SettingsDaemon/Power");
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

			var plug_grid = create_notebook_pages ("ac");
			var battery_grid = create_notebook_pages ("battery");
			var common_settings = create_common_settings ();
			var stack = new Gtk.Stack ();
			var stack_switcher = new Gtk.StackSwitcher ();
			stack_switcher.halign = Gtk.Align.CENTER;
			stack_switcher.stack = stack;
			stack.add_titled (plug_grid, "ac", _("Plugged In"));
			stack.add_titled (battery_grid, "battery", _("Battery Power"));
			stack_container.pack_start(stack_switcher, false, false, 0);
			stack_container.pack_start(stack, true, true, 0);
			stack_container.pack_end (common_settings);
			stack_container.margin = 12;
			stack_container.show_all ();
		}

		private Gtk.Grid create_common_settings () {
			var grid = new Gtk.Grid ();
			grid.margin = 12;
			grid.column_spacing = 12;
			grid.row_spacing = 12;

			var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
			separator.vexpand = true;
			separator.valign = Gtk.Align.END;
			grid.attach (separator, 0, 0, 2, 1);

			var brightness_label = new Gtk.Label (_("Screen brightness:"));
			label_size.add_widget (brightness_label);
			brightness_label.halign = Gtk.Align.END;

			var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10);
			scale.set_draw_value (false);
			scale.hexpand = true;
			scale.width_request = 480;
		
			scale.set_value (screen.Brightness);
		
			scale.value_changed.connect (() => {
				var val = (int) scale.get_value ();
				screen.Brightness = val;
			});
		
			grid.attach (brightness_label, 0, 1, 1, 1);
			grid.attach (scale, 1, 1, 1, 1);
			
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

			var scale_label = new Gtk.Label (_("Put the computer to sleep when inactive:"));
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
				var critical_box = new ComboBox (_("When battery power is critically low:"), "critical-battery-action");
				grid.attach (critical_box.label, 0, 2, 1, 1);
				label_size.add_widget (critical_box.label);
				grid.attach (critical_box, 1, 2, 1, 1);
			}
			
			return grid;
		}
	}
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Power plug");
    var plug = new Power.Plug ();
    return plug;
}
