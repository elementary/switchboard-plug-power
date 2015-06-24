namespace Power {
	class ActionComboBox : Gtk.ComboBoxText {
	
		public Gtk.Label label;
		private string key;
		
		// this maps combobox indices to gsettings enums
		private int[] map_to_sett = {1, 2, 3, 4, 5};
		// and vice-versa
		private int[] map_to_list = {4, 0, 1, 2, 3, 4};
		
		public ActionComboBox (string label, string key) {
			this.key = key;
			this.label = new Gtk.Label (label);
			this.label.halign = Gtk.Align.END;
			((Gtk.Misc) this.label).xalign = 1.0f;

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
}
