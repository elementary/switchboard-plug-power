public class PowerPlug.PowerPlug : Pantheon.Switchboard.Plug {

	Gtk.ListStore liststore_sleep;
	Gtk.ListStore liststore_power;
	public Gtk.ListStore liststore_critical;
	Gtk.ListStore liststore_time;
	public Gtk.ListStore liststore_lid;
	
	Gtk.TreeIter iter;
	
	Gtk.ComboBox critical_power;
	Gtk.ComboBox power_button;
	Gtk.ComboBox slp_button;
	Gtk.ComboBox lid_closed_battery;
	Gtk.ComboBox lid_closed_ac;
	
	Gtk.Scale scale;
	
	Gtk.CellRendererText cell;

	GLib.Settings settings;
	Granite.Widgets.StaticNotebook staticnotebook;
	Gtk.VBox vbox;

	public PowerPlug () {
		settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
		/***********************/
		
		/*ListStore Sleep*/
		liststore_sleep = new Gtk.ListStore (2, typeof (string), typeof (int));
		
		liststore_sleep.append (out iter);
		liststore_sleep.set (iter, 0, "Suspend", 1, 1);
		liststore_sleep.append (out iter);
		liststore_sleep.set (iter, 0, "Hibernate", 1, 3);
		
		/*ListStore Power*/
		liststore_power = new Gtk.ListStore (2, typeof (string), typeof (int));
		
		liststore_power.append (out iter);
		liststore_power.set (iter, 0, "Suspend", 1, 1);
		liststore_power.append (out iter);
		liststore_power.set (iter, 0, "Hibernate", 1, 3);
		liststore_power.append (out iter);
		liststore_power.set (iter, 0, "Do nothing", 1, 5);
		liststore_power.append (out iter);
		liststore_power.set (iter, 0, "Ask me", 1, 4);
		liststore_power.append (out iter);
		liststore_power.set (iter, 0, "Shutdown", 1, 2);
		
		/*ListStore Critical*/
		liststore_critical = new Gtk.ListStore (2, typeof (string), typeof (int));
		
		liststore_critical.append (out iter);
		liststore_critical.set (iter, 0, "Hibernate", 1, 3);
		liststore_critical.append (out iter);
		liststore_critical.set (iter, 0, "Shutdown", 1, 2);
		
		/*ListStore Time*/
		liststore_time = new Gtk.ListStore (2, typeof (string), typeof (int));
		
		liststore_time.append (out iter);
		liststore_time.set (iter, 0, "5 minutes", 1, 300);
		liststore_time.append (out iter);
		liststore_time.set (iter, 0, "10 minutes", 1, 500);
		liststore_time.append (out iter);
		liststore_time.set (iter, 0, "30 minutes", 1, 1800);
		liststore_time.append (out iter);
		liststore_time.set (iter, 0, "1 hour", 1, 3600);
		liststore_time.append (out iter);
		liststore_time.set (iter, 0, "Don't suspend", 1, 0);
		
		/*ListStore Lid closed*/
		liststore_lid = new Gtk.ListStore (2, typeof (string), typeof (int));
		
		liststore_lid.append (out iter);
		liststore_lid.set (iter, 0, "Suspend", 1, 1);
		liststore_lid.append (out iter);
		liststore_lid.set (iter, 0, "Hibernate", 1, 3);
		liststore_lid.append (out iter);
		liststore_lid.set (iter, 0, "Do nothing", 1, 0);
		
		/***********************/
		
		create_ui ();
		
		add (vbox);
		
	}
	
	void set_value_for_combo (Gtk.ComboBox combo, int val) {
		Gtk.TreeIter iter;
		Gtk.TreeModel model;
		int value_tmp;
		bool ret;

		/* get entry */
		model = combo.get_model ();
		ret = model.get_iter_first (out iter);
		if (!ret)
			return;
	
		/* try to make the UI match the setting */
		do {
			model.get (iter, 1, out value_tmp);
			if (val == value_tmp) {
				combo.set_active_iter (iter);
				break;
			}
		} while (model.iter_next (ref iter));
	}
	
	void update_pow_crit () {
		Gtk.TreeIter iter;
		bool ret = critical_power.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = critical_power.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("critical-battery-action", val);
	}
	
	void update_power_button () {
		Gtk.TreeIter iter;
		bool ret = power_button.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = power_button.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("button-power", val);
	}
	
	void update_slp_button () {
		Gtk.TreeIter iter;
		bool ret = slp_button.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = slp_button.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("button-sleep", val);
	}
	
	void update_lid_closed_combobox (Gtk.ComboBox combobox, string type) {
		Gtk.TreeIter iter;
		bool ret = combobox.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = combobox.get_model ();
		int val;
		model.get (iter, 1, out val);
		
		if (type == "ac") {
			settings.set_enum ("lid-close-ac-action", val);
		} else {
			settings.set_enum ("lid-close-battery-action", val);
		}
	}
	
	void create_ui () {
		int val;

		staticnotebook = new Granite.Widgets.StaticNotebook ();
		var plug_grid = create_notebook_pages ("ac");
		var battery_grid = create_notebook_pages ("battery");
		
		staticnotebook.append_page (plug_grid, new Gtk.Label(_("Plug in")));
		staticnotebook.append_page (battery_grid, new Gtk.Label(_("Battery")));
		
		// Power button row
		var power_button_label = new Gtk.Label (_("When the power button is pressed:"));
		power_button_label.halign = Gtk.Align.END;
		
		power_button = new Gtk.ComboBox.with_model (liststore_power);
		cell = new Gtk.CellRendererText();
		power_button.pack_start( cell, false );
		power_button.set_attributes( cell, "text", 0 );
		power_button.hexpand = true;
		
		val = settings.get_enum ("button-power");
		set_value_for_combo (power_button, val);
		power_button.changed.connect (update_power_button);
		
		//Sleep button row
		var slp_button_label = new Gtk.Label (_("When the sleep button is pressed:"));
		slp_button_label.halign = Gtk.Align.END;

		slp_button = new Gtk.ComboBox.with_model (liststore_sleep);
		cell = new Gtk.CellRendererText();
		slp_button.pack_start( cell, false );
		slp_button.set_attributes( cell, "text", 0 );
		slp_button.hexpand = true;
		
		val = settings.get_enum ("button-sleep");
		set_value_for_combo (slp_button, val);
		slp_button.changed.connect (update_slp_button);
		
		var grid = new Gtk.Grid ();
		grid.margin = 32;
		grid.attach (power_button_label, 0, 0, 1, 1);
		grid.attach (power_button, 1, 0, 1, 1);
		grid.attach (slp_button_label, 0, 1, 1, 1);
		grid.attach (slp_button, 1, 1, 1, 1);
		
		vbox = new Gtk.VBox (false, 4);
		vbox.pack_start (staticnotebook, true, true, 0);
		vbox.pack_start (new Gtk.HSeparator(), true, true, 0);
		vbox.pack_start (grid, true, true, 0);
		
	}
	
	Gtk.Grid create_notebook_pages (string type) 
	{
		int val;
	
		var grid = new Gtk.Grid ();
		grid.margin = 32;
		grid.column_spacing = grid.row_spacing = 4;

		var scale_label = new Gtk.Label (_("Put the computer to sleep when inactive:"));
		grid.attach (scale_label, 0, 0, 1, 1);

		scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 4000, 300);
		scale.set_draw_value (false);
		scale.add_mark (300, Gtk.PositionType.BOTTOM, _("5 min"));
		scale.add_mark (600, Gtk.PositionType.BOTTOM, _("10 min"));
		scale.add_mark (1800, Gtk.PositionType.BOTTOM, _("30 min"));
		scale.add_mark (3600, Gtk.PositionType.BOTTOM, _("1 hour"));
		scale.add_mark (4000, Gtk.PositionType.BOTTOM, _("Never"));
		scale.hexpand = true;
		grid.attach (scale, 1, 0, 1, 4);

		scale.value_changed.connect (() => {
			int vale = (int)scale.get_value ();
			if (vale <= 3600) {
				settings.set_int ("sleep-inactive-"+type+"-timeout", vale); }
			else if (vale == 4000) {
				settings.set_int ("sleep-inactive-"+type+"-timeout", 0);
			}
			});

		if (type == "ac") {
			var lid_closed_label = new Gtk.Label (_("When the lid is closed:"));
			lid_closed_label.halign = Gtk.Align.END;
			grid.attach (lid_closed_label, 0, 4, 1, 1);

			lid_closed_ac = new Gtk.ComboBox.with_model (liststore_lid);
			cell = new Gtk.CellRendererText();
			lid_closed_ac.pack_start( cell, false );
			lid_closed_ac.set_attributes( cell, "text", 0 );
			grid.attach (lid_closed_ac, 1, 4, 2, 1);

			val = settings.get_enum ("lid-close-"+type+"-action");
			set_value_for_combo (lid_closed_ac, val);
			lid_closed_ac.changed.connect (() => {update_lid_closed_combobox (lid_closed_ac, "ac");});
		} else {
			var lid_closed_label = new Gtk.Label (_("When the lid is closed:"));
			lid_closed_label.halign = Gtk.Align.END;
			grid.attach (lid_closed_label, 0, 4, 1, 1);

			lid_closed_battery = new Gtk.ComboBox.with_model (liststore_lid);
			cell = new Gtk.CellRendererText();
			lid_closed_battery.pack_start( cell, false );
			lid_closed_battery.set_attributes( cell, "text", 0 );
			grid.attach (lid_closed_battery, 1, 4, 2, 1);

			val = settings.get_enum ("lid-close-"+type+"-action");
			set_value_for_combo (lid_closed_battery, val);
			lid_closed_battery.changed.connect (() => {update_lid_closed_combobox (lid_closed_battery, "battery");});
		}

		if (type != "ac") {
			var critical_label = new Gtk.Label (_("When the power is critically low:"));
			critical_label.halign = Gtk.Align.END;
			grid.attach (critical_label, 0, 5, 1, 1);
			
			critical_power = new Gtk.ComboBox.with_model (liststore_critical);
			cell = new Gtk.CellRendererText();
			critical_power.pack_start( cell, false );
			critical_power.set_attributes( cell, "text", 0 );
			grid.attach (critical_power, 1, 5, 2, 1);

			val = settings.get_enum ("critical-battery-action");
			set_value_for_combo (critical_power, val);
			critical_power.changed.connect (update_pow_crit);
		}

		return grid;
	}
}

public static int main (string[] args) {

	Gtk.init (ref args);
	var plug = new PowerPlug.PowerPlug ();
	plug.register ("Power");
	plug.show_all ();
	Gtk.main ();
	return 0;
}
