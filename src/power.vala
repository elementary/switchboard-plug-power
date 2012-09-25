public class PowerPlug : Pantheon.Switchboard.Plug {

	Gtk.ListStore liststore_sleep;
	Gtk.ListStore liststore_power;
	Gtk.ListStore liststore_critical;
	Gtk.ListStore liststore_time;
	Gtk.ListStore liststore_lid;
	
	Gtk.TreeIter iter;
	
	Gtk.ComboBox ac_pow;
	Gtk.ComboBox bat_pow;
	Gtk.ComboBox pow_crit;
	Gtk.ComboBox but_pow;
	Gtk.ComboBox but_slp;
	Gtk.ComboBox lid_closed_ac;
	Gtk.ComboBox lid_closed_pow;

	GLib.Settings settings;
	Gtk.Grid grid;

	public PowerPlug () {
		settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");

	    /***********************/
	    
		/*ListStore Sleep*/
		liststore_sleep = new Gtk.ListStore (2, typeof (string), typeof (int));
		
		liststore_sleep.append (out iter);
		liststore_sleep.set (iter, 0, "Suspend", 1, 0);
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
		
		add (grid);
		
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
	
	void update_ac_pow () {
		Gtk.TreeIter iter;
		bool ret = ac_pow.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = ac_pow.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_int ("sleep-inactive-ac-timeout", val);
	}
	
	void update_bat_pow () {
		Gtk.TreeIter iter;
		bool ret = bat_pow.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = bat_pow.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_int ("sleep-inactive-battery-timeout", val);
	}
	
	void update_pow_crit () {
		Gtk.TreeIter iter;
		bool ret = pow_crit.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = pow_crit.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("critical-battery-action", val);
	}
	
	void update_but_pow () {
		Gtk.TreeIter iter;
		bool ret = but_pow.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = but_pow.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("button-power", val);
	}
	
	void update_but_slp () {
		Gtk.TreeIter iter;
		bool ret = but_slp.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = but_slp.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("button-sleep", val);
	}
	
	void update_lid_closed_ac () {
	    Gtk.TreeIter iter;
		bool ret = lid_closed_ac.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = lid_closed_ac.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("lid-close-ac-action", val);
	}
	
	void update_lid_closed_pow () {
	    Gtk.TreeIter iter;
		bool ret = lid_closed_pow.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = lid_closed_pow.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("lid-close-battery-action", val);
	}
	
	void create_ui () {
		int val;
		
		/*First row*/
		var on_ac_label = new Gtk.Label ("On AC power");
		var on_bat_label = new Gtk.Label ("On battery power");
		
		/*Second row*/
		var slp_label = new Gtk.Label ("Put the computer to sleep when inactive:");
		
		ac_pow = new Gtk.ComboBox.with_model (liststore_time);
		var cell = new Gtk.CellRendererText();
		ac_pow.pack_start( cell, false );
		ac_pow.set_attributes( cell, "text", 0 );
		ac_pow.set_data ("gsettings_key", "sleep-inactive-ac-timeout");
		
		val = settings.get_int ("sleep-inactive-ac-timeout");
		set_value_for_combo (ac_pow, val);
		ac_pow.changed.connect (update_ac_pow);
		
		bat_pow = new Gtk.ComboBox.with_model (liststore_time);
		cell = new Gtk.CellRendererText();
		bat_pow.pack_start( cell, false );
		bat_pow.set_attributes( cell, "text", 0 );
		
		val = settings.get_int ("sleep-inactive-battery-timeout");
		set_value_for_combo (bat_pow, val);
		bat_pow.changed.connect (update_bat_pow);
		
		/*Third row*/
		var pow_crit_label = new Gtk.Label ("When power is critically low:");
		
		pow_crit = new Gtk.ComboBox.with_model (liststore_critical);
		cell = new Gtk.CellRendererText();
		pow_crit.pack_start( cell, false );
		pow_crit.set_attributes( cell, "text", 0 );
		
		val = settings.get_enum ("critical-battery-action");
		set_value_for_combo (pow_crit, val);
		pow_crit.changed.connect (update_pow_crit);
		
		/*Fourth row*/
		var lid_closed_label = new Gtk.Label ("When the lid is closed:");
		
		lid_closed_ac = new Gtk.ComboBox.with_model (liststore_lid);
		cell = new Gtk.CellRendererText();
		lid_closed_ac.pack_start( cell, false );
		lid_closed_ac.set_attributes( cell, "text", 0 );
		
		val = settings.get_enum ("lid-close-ac-action");
		set_value_for_combo (lid_closed_ac, val);
		lid_closed_ac.changed.connect (update_lid_closed_ac);
		
		lid_closed_pow = new Gtk.ComboBox.with_model (liststore_lid);
		cell = new Gtk.CellRendererText();
		lid_closed_pow.pack_start( cell, false );
		lid_closed_pow.set_attributes( cell, "text", 0 );
		
		val = settings.get_enum ("lid-close-battery-action");
		set_value_for_combo (lid_closed_pow, val);
		lid_closed_pow.changed.connect (update_lid_closed_pow);
		
		/*Fifth row - Separator*/
		var separator = new Gtk.HSeparator ();
		
		/*Sixth row*/
		var but_pow_label = new Gtk.Label ("When the power button is pressed:");
		
		but_pow = new Gtk.ComboBox.with_model (liststore_power);
		cell = new Gtk.CellRendererText();
		but_pow.pack_start( cell, false );
		but_pow.set_attributes( cell, "text", 0 );
		
		val = settings.get_enum ("button-power");
		set_value_for_combo (but_pow, val);
		but_pow.changed.connect (update_but_pow);
		
        /*Seventh row*/
        var but_slp_label = new Gtk.Label ("When the sleep button is pressed:");

		but_slp = new Gtk.ComboBox.with_model (liststore_sleep);
		cell = new Gtk.CellRendererText();
		but_slp.pack_start( cell, false );
		but_slp.set_attributes( cell, "text", 0 );
		
		val = settings.get_enum ("button-sleep");
		set_value_for_combo (but_slp, val);
		but_slp.changed.connect (update_but_slp);
		
		/**/
	    grid = new Gtk.Grid ();
		grid.margin_bottom = grid.margin_top = 64;
		grid.margin_left = grid.margin_right = 256;
		grid.row_spacing = grid.column_spacing = 4;
		
		grid.attach (on_bat_label, 1, 0, 1, 1);
		grid.attach (on_ac_label, 2, 0, 1, 1);
		grid.attach (slp_label, 0, 1, 1, 1);
		grid.attach (bat_pow, 1, 1, 1, 1);
		grid.attach (ac_pow, 2, 1, 1, 1);
		grid.attach (pow_crit_label, 0, 2, 1, 1);
		grid.attach (pow_crit, 1, 2, 1, 1);
		grid.attach (lid_closed_label, 0, 3, 1, 1);
		grid.attach (lid_closed_pow, 1, 3, 1, 1);
		grid.attach (lid_closed_ac, 2, 3, 1, 1);
		grid.attach (separator, 0, 4, 3, 1);
		grid.attach (but_pow_label, 0, 5, 1, 1);
		grid.attach (but_pow, 1, 5, 1, 1);
		grid.attach (but_slp_label, 0, 6, 1, 1);
		grid.attach (but_slp, 1, 6, 1, 1);
		
	}
}

public static int main (string[] args) {

	Gtk.init (ref args);
	var plug = new PowerPlug ();
	plug.register ("Power");
	plug.show_all ();
	Gtk.main ();
	return 0;
}
