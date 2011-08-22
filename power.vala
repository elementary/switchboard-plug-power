public class PowerPlug : Pantheon.Switchboard.Plug {

	Gtk.ListStore liststore_sleep;
	Gtk.ListStore liststore_power;
	Gtk.ListStore liststore_critical;
	Gtk.ListStore liststore_time;
	
	Gtk.ComboBox ac_pow;
	Gtk.ComboBox bat_pow;
	Gtk.ComboBox pow_crit;
	Gtk.ComboBox but_pow;
	Gtk.ComboBox but_slp;
	Gtk.CheckButton check_ac;
	Gtk.CheckButton check_bat;

	GLib.Settings settings;
	Gtk.SizeGroup sizegroup;
	Gtk.SizeGroup sizegroup2;
	Gtk.VBox content_area;
	Gtk.VBox box;

	public PowerPlug () {
		settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");

		var builder = new Gtk.Builder ();
		try {
			builder.add_from_file ("power.ui");
		} catch (Error e) {
			stderr.printf ("Could not load UI: %s\n", e.message);
			return;
		} 
		liststore_sleep = builder.get_object ("liststore_sleep") as Gtk.ListStore;
		liststore_power = builder.get_object ("liststore_power") as Gtk.ListStore;
		liststore_critical = builder.get_object ("liststore_critical") as Gtk.ListStore;
		liststore_time = builder.get_object ("liststore_time") as Gtk.ListStore;
		
		create_ui ();
		
		add (box);
		
	}
	
	Gtk.CheckButton? add_label_widget (Gtk.Box parent, string text, Gtk.Widget widget, bool check_box=false) {
		var editable = (widget is Gtk.Bin) ? (widget as Gtk.Bin).get_child () : widget;
		var hbox = new Gtk.HBox (false, 0);
		parent.pack_start (hbox, false, false, 4);
		Gtk.Widget label;
		if (check_box)
			label = new Gtk.CheckButton.with_mnemonic (text);
		else
			label = new Gtk.Label.with_mnemonic (text);
		sizegroup.add_widget (label);
		sizegroup2.add_widget (widget);
		hbox.pack_start (label, false, false, 12);
		if (label is Gtk.Label)
			(label as Gtk.Label).xalign = 0.0f;
		hbox.pack_start (widget, false, false, 4);
		if (label is Gtk.CheckButton) {
			(label as Gtk.CheckButton).xalign = 0.0f;
			return (label as Gtk.CheckButton);
		}
		return null;
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
	
	void create_ui () {
		int val;
		
		sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
		sizegroup2 = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
		content_area = new Gtk.VBox (false, 0);
		box = new Gtk.VBox (false, 0);
		var vbox = new Gtk.VBox (false, 4);
		
		var label = new Gtk.Label ("Put the computer to sleep when inactive:");
		label.xalign = 0.0f;
		vbox.pack_start (label, false, false, 4);
		
		ac_pow = new Gtk.ComboBox.with_model (liststore_time);
		var cell = new Gtk.CellRendererText();
		ac_pow.pack_start( cell, false );
		ac_pow.set_attributes( cell, "text", 0 );
		ac_pow.set_data ("gsettings_key", "sleep-inactive-ac-timeout");
		
		val = settings.get_int ("sleep-inactive-ac-timeout");
		set_value_for_combo (ac_pow, val);
		ac_pow.changed.connect (update_ac_pow);
		
		
		check_ac = add_label_widget (vbox, "On AC power:",ac_pow,true);
		check_ac.toggled.connect ( () => {
			ac_pow.set_sensitive (check_ac.get_active ());
		});
		settings.bind ("sleep-inactive-ac", check_ac, "active", SettingsBindFlags.DEFAULT);
		
		bat_pow = new Gtk.ComboBox.with_model (liststore_time);
		cell = new Gtk.CellRendererText();
		bat_pow.pack_start( cell, false );
		bat_pow.set_attributes( cell, "text", 0 );
		
		val = settings.get_int ("sleep-inactive-battery-timeout");
		set_value_for_combo (bat_pow, val);
		bat_pow.changed.connect (update_bat_pow);
		
		check_bat = add_label_widget (vbox, "On battery power:",bat_pow,true);
		check_bat.toggled.connect ( () => {
			bat_pow.set_sensitive (check_bat.get_active ());
		});
		settings.bind ("sleep-inactive-battery", check_bat, "active", SettingsBindFlags.DEFAULT);
		
		content_area.pack_start (vbox, false, false, 4);

		pow_crit = new Gtk.ComboBox.with_model (liststore_critical);
		cell = new Gtk.CellRendererText();
		pow_crit.pack_start( cell, false );
		pow_crit.set_attributes( cell, "text", 0 );
		
		val = settings.get_enum ("critical-battery-action");
		set_value_for_combo (pow_crit, val);
		pow_crit.changed.connect (update_pow_crit);
		
		add_label_widget (content_area, "When power is critically low:",pow_crit);

		but_pow = new Gtk.ComboBox.with_model (liststore_power);
		cell = new Gtk.CellRendererText();
		but_pow.pack_start( cell, false );
		but_pow.set_attributes( cell, "text", 0 );
		
		val = settings.get_enum ("button-power");
		set_value_for_combo (but_pow, val);
		but_pow.changed.connect (update_but_pow);
		
		add_label_widget (content_area, "When the power button is pressed:",but_pow);

		but_slp = new Gtk.ComboBox.with_model (liststore_sleep);
		cell = new Gtk.CellRendererText();
		but_slp.pack_start( cell, false );
		but_slp.set_attributes( cell, "text", 0 );
		
		val = settings.get_enum ("button-sleep");
		set_value_for_combo (but_slp, val);
		but_slp.changed.connect (update_but_slp);
		
		add_label_widget (content_area, "When the sleep button is pressed:",but_slp);
		
		content_area.show_all ();
		var hbox = new Gtk.HBox (true, 0);
		hbox.pack_end (content_area, true, true, 0);
		box.pack_end (hbox, true, true, 0);
		box.set_border_width (40);
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
