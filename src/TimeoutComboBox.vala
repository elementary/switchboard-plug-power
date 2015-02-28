namespace Power {
	class TimeoutComboBox : Gtk.ComboBoxText {
	
		private GLib.Settings schema;
		private string key;
		
		private const int SECS_IN_MINUTE = 60;
		private const int[] timeout = {
			0,
			5 *  SECS_IN_MINUTE,
			10 * SECS_IN_MINUTE,
			15 * SECS_IN_MINUTE,
			30 * SECS_IN_MINUTE,
			45 * SECS_IN_MINUTE,
			60 * SECS_IN_MINUTE,
			120 * SECS_IN_MINUTE
		};
		
		public TimeoutComboBox (GLib.Settings schema, string key) {
			this.key = key;
			this.schema = schema;
			
			this.append_text (_("Never"));
			this.append_text (_("5 min"));
			this.append_text (_("10 min"));
			this.append_text (_("15 min"));
			this.append_text (_("30 min"));
			this.append_text (_("45 min"));
			this.append_text (_("1 hour"));
			this.append_text (_("2 hours"));
			
			this.hexpand = true;
			
			update_combo ();
			
			this.changed.connect (update_settings);
			this.schema.changed[key].connect (update_combo);
		}
		
		private void update_settings () {
			schema.set_int (key, timeout[active]);
		}
		
		// find closest timeout to our level
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
			int val = schema.get_int (key);
			
			// need to process value to comply our timeout level
			this.active = find_closest (val);
		}
	}
}
