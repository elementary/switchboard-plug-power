namespace Power {
	class TimeoutComboBox : Gtk.ComboBoxText {
	
		private string key;
		
		private int[] timeout = {0, 5*60, 10*60,15*60, 30*60, 60*60};
		
		public TimeoutComboBox (string key) {
			this.key = key;

			this.append_text (_("Never"));
			this.append_text (_("5 min"));
			this.append_text (_("10 min"));
			this.append_text (_("15 min"));
			this.append_text (_("30 min"));
			this.append_text (_("1 hour"));
		
			this.hexpand = true;
		
			update_combo ();
		
			this.changed.connect (update_settings);
			settings.changed[key].connect (update_combo);
		}

		private void update_settings () {
			message (timeout[active].to_string());
			settings.set_int (key, timeout[active]);
		}
		
		private int find_closest (int second) {
			int key = 0;
			foreach (int i in timeout) {
				if (second > i)
					key++;
				else
					break;
			}
			return key;
		}
	
		private void update_combo () {
			int val = settings.get_int (key);
			active = find_closest (val);
		}
	}
}