public class PowerPlug.PowerPlug : Pantheon.Switchboard.Plug {

	Gtk.ListStore liststore_sleep;
	Gtk.ListStore liststore_power;
	public Gtk.ListStore liststore_critical;
	Gtk.ListStore liststore_time;
	public Gtk.ListStore liststore_lid;
	
	Gtk.TreeIter iter;
	
	Gtk.ComboBox pow_crit;
	Gtk.ComboBox power_button;
	Gtk.ComboBox slp_button;
	Gtk.ComboBox lid_closed_battery;
	Gtk.ComboBox lid_closed_power;
	
	Gtk.Scale battery_slp_scale;
	Gtk.Scale power_slp_scale;
	
	Gtk.CellRendererText cell;

	GLib.Settings settings;
	Granite.Widgets.StaticNotebook staticnotebook;
	Gtk.VBox vbox;

	public PowerPlug () {
		settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
        int val;

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
	
	void update_power_slp_scale () {
		/*Gtk.TreeIter iter;
		bool ret = ac_pow.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry *//*
		var model = ac_pow.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_int ("sleep-inactive-ac-timeout", val);*/
	}
	
	void update_battery_slp_scale (double new_value) {
		int val = (int) Math.round (new_value);
		print ((string)val);
		settings.set_int ("sleep-inactive-battery-timeout", val);
		/*Gtk.TreeIter iter;
		bool ret = bat_pow.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */ /*
		var model = bat_pow.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_int ("sleep-inactive-battery-timeout", val);*/
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
	
	void update_lid_closed_battery () {
	    Gtk.TreeIter iter;
		bool ret = lid_closed_battery.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = lid_closed_battery.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("lid-close-ac-action", val);
	}
	
	void update_lid_closed_power () {
	    Gtk.TreeIter iter;
		bool ret = lid_closed_power.get_active_iter (out iter);
		if (!ret)
			return;

		/* get entry */
		var model = lid_closed_power.get_model ();
		int val;
		model.get (iter, 1, out val);

		settings.set_enum ("lid-close-battery-action", val);
	}
	
	void create_ui () {
		int val;
		
		staticnotebook = new Granite.Widgets.StaticNotebook ();
		
		// Battery page
		var bgrid = new Gtk.Grid ();
		bgrid.column_spacing = bgrid.row_spacing = 4;
		
		var slp_label = new Gtk.Label (_("Put the computer to sleep when inactive:"));
        bgrid.attach (slp_label, 0, 0, 1, 1);
        bgrid.margin = 32;
            
        battery_slp_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL,new Gtk.Adjustment(1800, 0, 3600, 300, 5, 0));
        battery_slp_scale.set_draw_value (false);
        battery_slp_scale.add_mark (300, Gtk.PositionType.BOTTOM, _("5 minutes"));
        battery_slp_scale.add_mark (600, Gtk.PositionType.BOTTOM, _("10 minutes"));
        battery_slp_scale.add_mark (1800, Gtk.PositionType.BOTTOM, _("30 minutes"));
        battery_slp_scale.set_hexpand (true);
		bgrid.attach (battery_slp_scale, 1, 0, 1, 4);
		
		//var scroll = new Gtk.ScrollType ();
		double new_value;
		battery_slp_scale.change_value.connect ((scroll, new_value) => { 
		    int vale = (int) Math.round (new_value);
		    print ((string)vale);
		    settings.set_int ("sleep-inactive-battery-timeout", vale);
		    return true;/*update_battery_slp_scale (new_value)*/ });
		
		var battery_slp_label = new Gtk.Label (_("1 hour"));
		bgrid.attach (battery_slp_label, 2, 0, 1, 1);
				
		var lid_closed_label = new Gtk.Label (_("When the lid is closed:"));
        lid_closed_label.halign = Gtk.Align.END;
        bgrid.attach (lid_closed_label, 0, 4, 1, 1);
            
        lid_closed_power = new Gtk.ComboBox.with_model (liststore_lid);
        cell = new Gtk.CellRendererText();
        lid_closed_power.pack_start( cell, false );
	    lid_closed_power.set_attributes( cell, "text", 0 );
	    bgrid.attach (lid_closed_power, 1, 4, 2, 1);
	    
	    val = settings.get_enum ("lid-close-battery-action");
		set_value_for_combo (lid_closed_power, val);
		lid_closed_power.changed.connect (update_lid_closed_power);
		    
	    var pow_crit_label = new Gtk.Label (_("When power is critically low:"));
	    pow_crit_label.halign = Gtk.Align.END;
	    bgrid.attach (pow_crit_label, 0, 5, 1, 1);
		
	    pow_crit = new Gtk.ComboBox.with_model (liststore_critical);
	    cell = new Gtk.CellRendererText();
	    pow_crit.pack_start( cell, false );
	    pow_crit.set_attributes( cell, "text", 0 );
        bgrid.attach (pow_crit, 1, 5, 2, 1);
        
        val = settings.get_enum ("critical-battery-action");
		set_value_for_combo (pow_crit, val);
		pow_crit.changed.connect (update_pow_crit);
        
        // Plug in Page
        var pgrid = new Gtk.Grid ();
        pgrid.margin = 32;
        pgrid.column_spacing = pgrid.row_spacing = 4;
        
        var p_slp_label = new Gtk.Label (_("Put the computer to sleep when inactive:"));
        pgrid.attach (p_slp_label, 0, 0, 1, 1);
        
        power_slp_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL,new Gtk.Adjustment(1800, 0, 3600, 300, 5, 0));
        power_slp_scale.set_draw_value (false);
        power_slp_scale.add_mark (300, Gtk.PositionType.BOTTOM, _("5 minutes"));
        power_slp_scale.add_mark (600, Gtk.PositionType.BOTTOM, _("10 minutes"));
        power_slp_scale.add_mark (1800, Gtk.PositionType.BOTTOM, _("30 minutes"));
        power_slp_scale.set_hexpand (true);
        pgrid.attach (power_slp_scale, 1, 0, 1, 4);
        
        var power_hour_label = new Gtk.Label (_("1 hour"));
        pgrid.attach (power_hour_label, 2, 0, 1, 1);
        
        var power_lid_closed_label = new Gtk.Label (_("When the lid is closed:"));
        power_lid_closed_label.halign = Gtk.Align.END;
        pgrid.attach (power_lid_closed_label, 0, 4, 1, 1);
        
        lid_closed_power = new Gtk.ComboBox.with_model (liststore_lid);
		cell = new Gtk.CellRendererText();
		lid_closed_power.pack_start( cell, false );
		lid_closed_power.set_attributes( cell, "text", 0 );
		pgrid.attach (lid_closed_power, 1, 4, 2, 1);
        
        staticnotebook.append_page (pgrid, new Gtk.Label (_("Plug in")));
        staticnotebook.append_page (bgrid, new Gtk.Label (_("Battery")));
        
        
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
		
        // Sleep button row
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
}

public static int main (string[] args) {

	Gtk.init (ref args);
	var plug = new PowerPlug.PowerPlug ();
	plug.register ("Power");
	plug.show_all ();
	Gtk.main ();
	return 0;
}
